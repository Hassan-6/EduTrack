// lib/services/calendar_sync_service.dart
import 'package:device_calendar/device_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._internal();
  factory CalendarSyncService() => _instance;
  CalendarSyncService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  String? _selectedCalendarId;
  bool _initialized = false;

  // Initialize calendar sync
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      
      // Check if sync is enabled
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('calendarSyncEnabled') ?? false;
      
      if (!syncEnabled) {
        print('Calendar sync is disabled');
        return false;
      }

      // Request calendar permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('Calendar permissions not granted');
        return false;
      }

      // Get or create EduTrack calendar
      await _getOrCreateCalendar();
      
      _initialized = true;
      return true;
    } catch (e) {
      print('Error initializing calendar sync: $e');
      return false;
    }
  }

  // Request calendar permissions
  Future<bool> _requestPermissions() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  // Get or create EduTrack calendar
  Future<void> _getOrCreateCalendar() async {
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        print('Failed to retrieve calendars');
        return;
      }

      // Look for existing EduTrack calendar
      final edutrackCalendar = calendarsResult.data!.firstWhere(
        (cal) => cal.name == 'EduTrack',
        orElse: () => Calendar(id: ''),
      );

      if (edutrackCalendar.id != null && edutrackCalendar.id!.isNotEmpty) {
        _selectedCalendarId = edutrackCalendar.id;
        print('Found existing EduTrack calendar: $_selectedCalendarId');
      } else {
        // For device_calendar plugin, we typically use the default calendar
        // or select one from available calendars. Creating new calendars
        // is not universally supported across platforms.
        if (calendarsResult.data!.isNotEmpty) {
          _selectedCalendarId = calendarsResult.data!.first.id;
          print('Using default calendar: $_selectedCalendarId');
        }
      }
    } catch (e) {
      print('Error getting/creating calendar: $e');
    }
  }

  // Sync event to device calendar
  Future<String?> syncEventToDevice({
    required String eventId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      // Check if sync is enabled
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('calendarSyncEnabled') ?? false;
      
      if (!syncEnabled) {
        print('Calendar sync is disabled');
        return null;
      }

      if (!_initialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      if (_selectedCalendarId == null) {
        print('No calendar selected');
        return null;
      }

      final event = Event(
        _selectedCalendarId,
        eventId: eventId,
        title: title,
        description: description,
        start: tz.TZDateTime.from(startDate, tz.local),
        end: tz.TZDateTime.from(endDate, tz.local),
        location: location,
      );

      final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      
      if (createResult?.isSuccess == true && createResult?.data != null) {
        print('Event synced to device calendar: ${createResult!.data}');
        return createResult.data;
      } else {
        print('Failed to sync event: ${createResult?.errors}');
        return null;
      }
    } catch (e) {
      print('Error syncing event to device: $e');
      return null;
    }
  }

  // Update event on device calendar
  Future<String?> updateEventOnDevice({
    required String eventId,
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? location,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('calendarSyncEnabled') ?? false;
      
      if (!syncEnabled) {
        print('Calendar sync is disabled');
        return null;
      }

      if (!_initialized) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      if (_selectedCalendarId == null) {
        print('No calendar selected');
        return null;
      }

      final event = Event(
        _selectedCalendarId,
        eventId: eventId,
        title: title,
        description: description,
        start: tz.TZDateTime.from(startDate, tz.local),
        end: tz.TZDateTime.from(endDate, tz.local),
        location: location,
      );

      final updateResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      
      if (updateResult?.isSuccess == true && updateResult?.data != null) {
        print('Event updated on device calendar: ${updateResult!.data}');
        return updateResult.data;
      } else {
        print('Failed to update event: ${updateResult?.errors}');
        return null;
      }
    } catch (e) {
      print('Error updating event on device: $e');
      return null;
    }
  }

  // Delete event from device calendar
  Future<bool> deleteEventFromDevice(String eventId) async {
    try {
      if (!_initialized || _selectedCalendarId == null) return false;

      final deleteResult = await _deviceCalendarPlugin.deleteEvent(
        _selectedCalendarId!,
        eventId,
      );

      return deleteResult.isSuccess;
    } catch (e) {
      print('Error deleting event from device: $e');
      return false;
    }
  }

  // Sync all existing events from Firestore to device calendar
  Future<void> syncAllEventsToDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncEnabled = prefs.getBool('calendarSyncEnabled') ?? false;
      
      if (!syncEnabled) {
        print('Calendar sync is disabled');
        return;
      }

      if (!_initialized) {
        final initialized = await initialize();
        if (!initialized) return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Get all events from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calendar_events')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final eventDate = (data['date'] as Timestamp).toDate();
        
        // Parse start and end times
        final startTime = data['startTime'] as String? ?? '09:00';
        final endTime = data['endTime'] as String? ?? '10:00';
        
        final startParts = startTime.split(':');
        final endParts = endTime.split(':');
        
        final startDate = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        
        final endDate = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        await syncEventToDevice(
          eventId: doc.id,
          title: data['title'] ?? 'Untitled Event',
          description: data['description'] ?? '',
          startDate: startDate,
          endDate: endDate,
        );
      }

      print('All events synced to device calendar');
    } catch (e) {
      print('Error syncing all events: $e');
    }
  }

  // Clear all synced events from device calendar
  Future<void> clearAllSyncedEvents() async {
    try {
      if (!_initialized || _selectedCalendarId == null) return;

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        _selectedCalendarId!,
        RetrieveEventsParams(
          startDate: DateTime.now().subtract(const Duration(days: 365)),
          endDate: DateTime.now().add(const Duration(days: 365)),
        ),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        for (var event in eventsResult.data!) {
          await _deviceCalendarPlugin.deleteEvent(
            _selectedCalendarId!,
            event.eventId!,
          );
        }
      }

      print('All synced events cleared from device calendar');
    } catch (e) {
      print('Error clearing synced events: $e');
    }
  }

  // Check if calendar sync is enabled
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('calendarSyncEnabled') ?? false;
  }

  // Enable/disable calendar sync
  Future<void> toggleSync(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendarSyncEnabled', enabled);

    if (enabled) {
      // Initialize and sync all events
      await initialize();
      await syncAllEventsToDevice();
    } else {
      // Clear synced events when disabled
      await clearAllSyncedEvents();
      _initialized = false;
    }
  }
}
