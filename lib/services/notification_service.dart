// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _initialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_initialized) {
      print('NotificationService already initialized');
      return;
    }

    print('Initializing NotificationService...');
    
    try {
      // Initialize timezone
      print('Initializing timezones...');
      tz.initializeTimeZones();
      print('Timezones initialized');

      // Request permissions
      print('Requesting notification permissions...');
      await _requestPermissions();

      // Initialize local notifications
      print('Initializing local notifications...');
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      print('Initializing Firebase messaging...');
      await _initializeFirebaseMessaging();

      _initialized = true;
      print('NotificationService initialization complete!');
    } catch (e, stackTrace) {
      print('Error initializing NotificationService: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined notification permission');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      showLocalNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'EduTrack',
        body: notification.body ?? '',
        payload: data.toString(),
      );
    }
  }

  // Handle background/terminated messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Opened app from notification: ${message.messageId}');
    // Handle navigation based on notification type
    _handleNotificationNavigation(message.data);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Parse payload and navigate accordingly
    if (response.payload != null) {
      _handleNotificationNavigation(_parsePayload(response.payload!));
    }
  }

  // Parse payload string to map
  Map<String, dynamic> _parsePayload(String payload) {
    // Simple parsing - you may want to use json.decode for complex data
    return {'raw': payload};
  }

  // Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This will be implemented in the UI layer
    // Store the data to be picked up by the app
  }

  // Show local notification immediately (public for ActivityMonitorService)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Check if notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    if (!notificationsEnabled) {
      print('Notifications are disabled by user');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'edutrack_channel',
      'EduTrack Notifications',
      channelDescription: 'Notifications for tasks, events, and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      print('scheduleNotification called:');
      print('  ID: $id');
      print('  Title: $title');
      print('  Scheduled for: $scheduledDate');
      print('  Current time: ${DateTime.now()}');
      
      // Check if notifications are enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      if (!notificationsEnabled) {
        print('Notifications are disabled by user');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'edutrack_channel',
        'EduTrack Notifications',
        channelDescription: 'Notifications for tasks, events, and updates',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      print('  Scheduled TZ time: $scheduledTZ');
      
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      print('  Notification scheduled successfully!');
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Create and save notification to Firestore
  Future<String> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    DateTime? scheduledFor,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
    );

    final docRef = await _firestore
        .collection('notifications')
        .add(notification.toFirestore());

    return docRef.id;
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Get user notifications stream
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Schedule task reminder based on user preferences
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required String taskDescription,
    required DateTime dueDate,
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      
      if (!notificationsEnabled) {
        print('Notifications are disabled by user');
        return;
      }
      
      final reminderFrequency = prefs.getString('reminderFrequency') ?? '1 Day';

      // Calculate reminder time based on time before due date
      DateTime reminderTime;
      switch (reminderFrequency) {
        case '1 Hour':
          reminderTime = dueDate.subtract(const Duration(hours: 1));
          break;
        case '4 Hours':
          reminderTime = dueDate.subtract(const Duration(hours: 4));
          break;
        case '8 Hours':
          reminderTime = dueDate.subtract(const Duration(hours: 8));
          break;
        case '1 Day':
          reminderTime = dueDate.subtract(const Duration(days: 1));
          break;
        case '3 Days':
          reminderTime = dueDate.subtract(const Duration(days: 3));
          break;
        case '5 Days':
          reminderTime = dueDate.subtract(const Duration(days: 5));
          break;
        case '7 Days':
          reminderTime = dueDate.subtract(const Duration(days: 7));
          break;
        default:
          reminderTime = dueDate.subtract(const Duration(days: 1));
      }

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        print('Scheduling task reminder:');
        print('  Task: $taskTitle');
        print('  Due date: $dueDate');
        print('  Reminder time: $reminderTime');
        print('  Reminder frequency: $reminderFrequency');
        
        await scheduleNotification(
          id: taskId.hashCode,
          title: 'Task Reminder: $taskTitle',
          body: taskDescription.isEmpty
              ? 'Your task is due soon!'
              : taskDescription,
          scheduledDate: reminderTime,
          payload: 'task:$taskId',
        );
        
        print('Task reminder scheduled successfully');

        // Save to Firestore
        await createNotification(
          userId: userId,
        type: NotificationType.todoReminder,
        title: 'Task Reminder: $taskTitle',
        body: taskDescription.isEmpty
            ? 'Your task is due soon!'
            : taskDescription,
          data: {'taskId': taskId, 'taskTitle': taskTitle},
          scheduledFor: reminderTime,
        );
      } else {
        print('Task reminder NOT scheduled - reminder time ($reminderTime) is in the past');
        print('  Due date: $dueDate');
        print('  Reminder frequency: $reminderFrequency');
      }
    } catch (e) {
      print('Error scheduling task reminder: $e');
      print('  Stack trace: ${StackTrace.current}');
      // Don't throw - allow task creation to succeed even if notification fails
    }
  }  // Schedule calendar event reminder
  Future<void> scheduleCalendarReminder({
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required String userId,
  }) async {
    // Schedule notification for day before
    final dayBefore = eventDate.subtract(const Duration(days: 1));
    if (dayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: '$eventId-daybefore'.hashCode,
        title: 'Upcoming Event Tomorrow',
        body: eventTitle,
        scheduledDate: dayBefore,
        payload: 'calendar:$eventId',
      );

      await createNotification(
        userId: userId,
        type: NotificationType.calendarReminder,
        title: 'Upcoming Event Tomorrow',
        body: eventTitle,
        data: {'eventId': eventId, 'eventTitle': eventTitle},
        scheduledFor: dayBefore,
      );
    }

    // Schedule notification for day of event (1 hour before)
    final oneHourBefore = eventDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: '$eventId-today'.hashCode,
        title: 'Event Starting Soon',
        body: '$eventTitle starts in 1 hour',
        scheduledDate: oneHourBefore,
        payload: 'calendar:$eventId',
      );

      await createNotification(
        userId: userId,
        type: NotificationType.calendarReminder,
        title: 'Event Starting Soon',
        body: '$eventTitle starts in 1 hour',
        data: {'eventId': eventId, 'eventTitle': eventTitle},
        scheduledFor: oneHourBefore,
      );
    }
  }

  // Notify QnA response
  Future<void> notifyQnaResponse({
    required String postOwnerId,
    required String questionTitle,
    required String responderName,
    required String postId,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Don't notify if the responder is the post owner (self-reply)
    if (currentUserId == postOwnerId) {
      return;
    }
    
    try {
      // Create notification in Firestore for the question owner
      await createNotification(
        userId: postOwnerId,
        type: NotificationType.qnaResponse,
        title: 'New Reply to Your Question',
        body: '$responderName replied to "$questionTitle"',
        data: {
          'questionId': postId,
          'responderName': responderName,
          'questionTitle': questionTitle,
        },
      );
      
      print('QnA notification created: $responderName replied to "$questionTitle" for user $postOwnerId');
    } catch (e) {
      print('Error creating QnA notification: $e');
    }
  }

  // Notify students about presented question
  Future<void> notifyQuestionPresented({
    required List<String> studentIds,
    required String courseName,
    required String instructorName,
  }) async {
    // Note: Cannot create Firestore notifications for other users due to security rules
    // This would require Cloud Functions to create notifications server-side
    // For now, log the notification attempt
    print('Question presented in $courseName by $instructorName to ${studentIds.length} students');
  }

  // Notify students about scheduled quiz
  Future<void> notifyQuizScheduled({
    required List<String> studentIds,
    required String courseName,
    required String quizTitle,
    required DateTime quizDate,
  }) async {
    // Note: Cannot create Firestore notifications for other users due to security rules
    // This would require Cloud Functions to create notifications server-side
    // For now, log the notification attempt
    print('Quiz scheduled in $courseName: $quizTitle on ${quizDate.toString().split(' ')[0]} for ${studentIds.length} students');
  }

  // Notify instructor about enrollment request
  Future<void> notifyEnrollmentRequest({
    required String instructorId,
    required String studentName,
    required String courseName,
    required String courseId,
  }) async {
    // Note: Cannot create Firestore notification for another user due to security rules
    // This would require Cloud Functions to create notifications server-side
    // For now, log the notification attempt
    print('Enrollment request: $studentName wants to enroll in $courseName (Instructor: $instructorId)');
  }

  // Test notification (for debugging)
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Test Notification',
      body: 'This is a test notification from EduTrack',
      payload: 'test',
    );
    print('Test notification sent!');
  }

  // Test scheduled notification (for debugging)
  Future<void> scheduleTestNotification({int secondsFromNow = 10}) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: secondsFromNow));
    await scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Test Scheduled Notification',
      body: 'This notification was scheduled $secondsFromNow seconds ago',
      scheduledDate: scheduledTime,
      payload: 'test_scheduled',
    );
    print('Test notification scheduled for $secondsFromNow seconds from now');
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
