import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_entry_screen.dart';
import '../utils/theme_provider.dart';
import '../utils/calendar_event.dart';
import '../services/calendar_sync_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<CalendarEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calendar_events')
          .orderBy('date', descending: false)
          .get();

      setState(() {
        _events = snapshot.docs.map((doc) {
          final data = doc.data();
          return CalendarEvent(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            date: (data['date'] as Timestamp).toDate(),
            startTime: data['startTime'] ?? '',
            endTime: data['endTime'] ?? '',
            type: _parseEventType(data['type'] ?? 'event'),
            color: _getColorForType(_parseEventType(data['type'] ?? 'event')),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  EventType _parseEventType(String type) {
    switch (type) {
      case 'assignment':
        return EventType.assignment;
      case 'exam':
        return EventType.exam;
      case 'event':
      default:
        return EventType.event;
    }
  }

  Color _getColorForType(EventType type) {
    switch (type) {
      case EventType.assignment:
        return const Color(0xFF4E9FEC);
      case EventType.event:
        return const Color(0xFF5CD6C0);
      case EventType.exam:
        return const Color(0xFFFB923C);
    }
  }

  List<CalendarEvent> getUpcomingEvents({int limit = 1}) {
    final now = DateTime.now();
    final upcoming = _events
        .where((event) => event.date.isAfter(now))
        .toList();
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.take(limit).toList();
  }

  List<CalendarEvent> getTodaysEvents() {
    final today = DateTime.now();
    return _getEventsForDay(today);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => isSameDay(event.date, day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text('Are you sure you want to delete "${event.title}"?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('calendar_events')
          .doc(event.id)
          .delete();

      // Delete from device calendar
      final syncService = CalendarSyncService();
      await syncService.deleteEventFromDevice(event.id);

      await _loadEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  void _editEvent(CalendarEvent event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEntryScreen(event: event)),
    );

    if (result != null && result is CalendarEvent) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('calendar_events')
            .doc(result.id)
            .update({
          'title': result.title,
          'description': result.description,
          'date': result.date,
          'startTime': result.startTime,
          'endTime': result.endTime,
          'type': _eventTypeToString(result.type),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update device calendar
        final syncService = CalendarSyncService();
        final syncEnabled = await syncService.isSyncEnabled();
        
        if (syncEnabled) {
          DateTime startDateTime = result.date;
          DateTime endDateTime = result.date;
          
          if (result.startTime != 'All Day' && result.startTime.isNotEmpty) {
            final startParts = result.startTime.split(':');
            if (startParts.length == 2) {
              final hour = int.tryParse(startParts[0].trim()) ?? 0;
              final minute = int.tryParse(startParts[1].trim()) ?? 0;
              startDateTime = DateTime(
                result.date.year,
                result.date.month,
                result.date.day,
                hour,
                minute,
              );
            }
          }
          
          if (result.endTime.isNotEmpty && result.endTime != 'All Day') {
            final endParts = result.endTime.split(':');
            if (endParts.length == 2) {
              final hour = int.tryParse(endParts[0].trim()) ?? 0;
              final minute = int.tryParse(endParts[1].trim()) ?? 0;
              endDateTime = DateTime(
                result.date.year,
                result.date.month,
                result.date.day,
                hour,
                minute,
              );
            }
          } else {
            endDateTime = DateTime(
              result.date.year,
              result.date.month,
              result.date.day,
              23,
              59,
            );
          }

          await syncService.updateEventOnDevice(
            eventId: result.id,
            title: result.title,
            description: result.description,
            startDate: startDateTime,
            endDate: endDateTime,
          );
        }

        await _loadEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${result.title}" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating event: $e')),
          );
        }
      }
    }
  }

  void _addNewEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );

    if (result != null && result is CalendarEvent) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('calendar_events')
            .add({
          'title': result.title,
          'description': result.description,
          'date': result.date,
          'startTime': result.startTime,
          'endTime': result.endTime,
          'type': _eventTypeToString(result.type),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Sync to device calendar if enabled
        final syncService = CalendarSyncService();
        final syncEnabled = await syncService.isSyncEnabled();
        
        if (syncEnabled) {
          // Parse times for device calendar
          DateTime startDateTime = result.date;
          DateTime endDateTime = result.date;
          
          if (result.startTime != 'All Day' && result.startTime.isNotEmpty) {
            final startParts = result.startTime.split(':');
            if (startParts.length == 2) {
              final hour = int.tryParse(startParts[0].trim()) ?? 0;
              final minute = int.tryParse(startParts[1].trim()) ?? 0;
              startDateTime = DateTime(
                result.date.year,
                result.date.month,
                result.date.day,
                hour,
                minute,
              );
            }
          }
          
          if (result.endTime.isNotEmpty && result.endTime != 'All Day') {
            final endParts = result.endTime.split(':');
            if (endParts.length == 2) {
              final hour = int.tryParse(endParts[0].trim()) ?? 0;
              final minute = int.tryParse(endParts[1].trim()) ?? 0;
              endDateTime = DateTime(
                result.date.year,
                result.date.month,
                result.date.day,
                hour,
                minute,
              );
            }
          } else {
            // All day event - set end to 11:59 PM
            endDateTime = DateTime(
              result.date.year,
              result.date.month,
              result.date.day,
              23,
              59,
            );
          }

          await syncService.syncEventToDevice(
            eventId: docRef.id,
            title: result.title,
            description: result.description,
            startDate: startDateTime,
            endDate: endDateTime,
          );
        }

        await _loadEvents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${result.title}" added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding event: $e')),
          );
        }
      }
    }
  }

  String _eventTypeToString(EventType type) {
    switch (type) {
      case EventType.assignment:
        return 'assignment';
      case EventType.event:
        return 'event';
      case EventType.exam:
        return 'exam';
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Calendar',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: _onFormatChanged,
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    return _getEventsForDay(day);
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      
                      final validEvents = events.whereType<CalendarEvent>();
                      final eventTypes = validEvents.map((e) => e.type).toSet();
                      
                      if (eventTypes.isEmpty) return const SizedBox.shrink();
                      
                      if (eventTypes.length == 1) {
                        final eventType = eventTypes.first;
                        return Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getColorForType(eventType),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }
                      
                      return Positioned(
                        bottom: 1,
                        right: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: eventTypes.take(3).map((type) {
                            return Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: _getColorForType(type),
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    titleTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                    ),
                    weekendTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                    ),
                    outsideTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 14,
                    ),
                    selectedTextStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    todayTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(const Color(0xFF4E9FEC), 'Assignment'),
                    _buildLegendItem(const Color(0xFF5CD6C0), 'Event'),
                    _buildLegendItem(const Color(0xFFFB923C), 'Exam'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDay != null 
                          ? '${_getMonthName(_selectedDay!.month)} ${_selectedDay!.day}, ${_selectedDay!.year}'
                          : 'Select a date',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (selectedEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          'No events for this day',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      ...selectedEvents.map((event) => _buildEventItem(event)).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCalendarFloatingActionButton(themeProvider),
    );
  }

  Widget _buildCalendarFloatingActionButton(ThemeProvider themeProvider) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            spreadRadius: 0,
            offset: Offset(0, 10),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x19000000),
            spreadRadius: 0,
            offset: Offset(0, 4),
            blurRadius: 6,
          ),
        ],
        gradient: themeProvider.gradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9999),
          onTap: _addNewEvent,
          child: const Center(
            child: Icon(
              Icons.add,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  title: Text('Edit Event', style: GoogleFonts.inter()),
                  onTap: () {
                    Navigator.pop(context);
                    _editEvent(event);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Event', style: GoogleFonts.inter(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEvent(event);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Icon(
              _getEventIcon(event.type),
              color: event.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.endTime.isEmpty 
                      ? 'Due: ${event.startTime}'
                      : '${event.startTime} - ${event.endTime}',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getEventTypeText(event.type),
                    style: GoogleFonts.inter(
                      color: event.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.assignment:
        return Icons.assignment;
      case EventType.event:
        return Icons.event;
      case EventType.exam:
        return Icons.quiz;
    }
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.assignment:
        return 'Assignment';
      case EventType.event:
        return 'Event';
      case EventType.exam:
        return 'Exam';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
