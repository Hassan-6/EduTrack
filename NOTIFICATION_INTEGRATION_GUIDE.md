# EduTrack Notification System Integration Guide

This guide explains how to integrate the notification system into various screens of the EduTrack application.

## Overview

The notification system has been implemented with the following components:
- `notification_model.dart` - Data model for notifications
- `notification_service.dart` - Service handling local and push notifications
- `notifications_screen.dart` - UI for viewing all notifications
- Firebase Cloud Messaging (FCM) for push notifications
- Flutter Local Notifications for local/scheduled notifications

## Setup Requirements

### 1. Install Dependencies

The following packages have been added to `pubspec.yaml`:
```yaml
firebase_messaging: ^14.7.10
flutter_local_notifications: ^17.0.0
timezone: ^0.9.2
```

Run: `flutter pub get`

### 2. Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    
    <application>
        <!-- Add inside <application> tag -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="edutrack_channel" />
    </application>
</manifest>
```

### 3. iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Integration Steps

### 1. To-Do List Screen Integration

**File**: `lib/screens/to_do_list_screen.dart` or `lib/screens/new_task_screen.dart`

When creating or updating a task, schedule a notification:

```dart
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your save/create task method:
Future<void> _saveTask() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Your existing task creation code...
  final task = Task(
    id: taskId,
    title: titleController.text,
    description: descriptionController.text,
    dueDate: selectedDate,
    // ... other fields
  );

  // Save to Firestore (your existing code)
  await FirebaseService.createTask(task);

  // Schedule notification reminder
  await NotificationService().scheduleTaskReminder(
    taskId: task.id,
    taskTitle: task.title,
    taskDescription: task.description,
    dueDate: task.dueDate,
    userId: user.uid,
  );
}
```

### 2. Calendar Screen Integration

**File**: `lib/screens/calendar_screen.dart`

When creating a calendar event, schedule reminders:

```dart
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your save/create event method:
Future<void> _saveEvent() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Your existing event creation code...
  final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
  final eventTitle = titleController.text;
  final eventDate = selectedDateTime;

  // Save to Firestore (your existing code)
  // ...

  // Schedule calendar reminders (day before and day of)
  await NotificationService().scheduleCalendarReminder(
    eventId: eventId,
    eventTitle: eventTitle,
    eventDate: eventDate,
    userId: user.uid,
  );
}
```

### 3. QnA Wall Integration

**File**: `lib/screens/qna_wall_screen.dart`

When someone responds to a QnA post:

```dart
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your addResponse method:
Future<void> _addResponse(String postId, String questionTitle, String postOwnerId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Get current user's name
  final userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final responderName = userData.data()?['name'] ?? 'Someone';

  // Your existing code to add response to Firestore
  // ...

  // Don't notify if responding to own post
  if (postOwnerId != user.uid) {
    // Notify the post owner
    await NotificationService().notifyQnaResponse(
      postOwnerId: postOwnerId,
      questionTitle: questionTitle,
      responderName: responderName,
      postId: postId,
    );
  }
}
```

### 4. Present Question Screen Integration (Instructor)

**File**: `lib/screens/present_question_screen.dart`

When instructor presents a question:

```dart
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your presentQuestion method:
Future<void> _presentQuestion() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Get instructor name
  final userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final instructorName = userData.data()?['name'] ?? 'Instructor';

  // Get all enrolled students
  final courseDoc = await FirebaseFirestore.instance
      .collection('courses')
      .doc(widget.course.id)
      .get();
  final List<String> enrolledStudents = 
      List<String>.from(courseDoc.data()?['enrolledStudents'] ?? []);

  // Your existing code to present question
  // ...

  // Notify all enrolled students
  await NotificationService().notifyQuestionPresented(
    studentIds: enrolledStudents,
    courseName: widget.course.name,
    instructorName: instructorName,
  );
}
```

### 5. Schedule Quiz Screen Integration (Instructor)

**File**: `lib/screens/schedule_quiz_screen.dart`

When instructor schedules a quiz:

```dart
import '../services/notification_service.dart';

// In your scheduleQuiz method:
Future<void> _scheduleQuiz() async {
  // Get all enrolled students
  final courseDoc = await FirebaseFirestore.instance
      .collection('courses')
      .doc(widget.course.id)
      .get();
  final List<String> enrolledStudents = 
      List<String>.from(courseDoc.data()?['enrolledStudents'] ?? []);

  final quizTitle = titleController.text;
  final quizDate = selectedDateTime;

  // Your existing code to schedule quiz
  // ...

  // Notify all enrolled students
  await NotificationService().notifyQuizScheduled(
    studentIds: enrolledStudents,
    courseName: widget.course.name,
    quizTitle: quizTitle,
    quizDate: quizDate,
  );
}
```

### 6. Course Enrollment Integration (Student)

**File**: `lib/screens/course_enrollment_screen.dart` or `lib/screens/ins_course_detail_screen.dart`

When a student sends an enrollment request:

```dart
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// In your sendEnrollmentRequest method:
Future<void> _sendEnrollmentRequest(Course course) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // Get student name
  final userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  final studentName = userData.data()?['name'] ?? 'A student';

  // Your existing code to send enrollment request
  // ...

  // Notify the instructor
  await NotificationService().notifyEnrollmentRequest(
    instructorId: course.instructorId,
    studentName: studentName,
    courseName: course.name,
    courseId: course.id,
  );
}
```

## Adding Notification Bell Icon

Add a notification bell icon to your main menu screens to navigate to the notifications screen.

**Example for MainMenuScreen**:

```dart
// In the AppBar or header
StreamBuilder<int>(
  stream: NotificationService().getUnreadCount(user.uid),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
)
```

## Firestore Security Rules

Add these rules to `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Notifications collection
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      // System can create notifications (you may want to restrict this further)
      allow create: if request.auth != null;
      // Users can update their own notifications (e.g., mark as read)
      allow update: if request.auth != null && resource.data.userId == request.auth.uid;
      // Users can delete their own notifications
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Testing

1. **Test Local Notifications**:
   - Create a task with a due date in the near future
   - Check if notification appears at the scheduled time

2. **Test Push Notifications**:
   - Have one user create a QnA post
   - Have another user respond
   - Check if the first user receives a notification

3. **Test Notification Screen**:
   - Navigate to `/notifications` route
   - Verify all notifications are displayed
   - Test marking notifications as read

## Troubleshooting

### Android Issues
- Ensure notification permissions are granted in app settings
- Check that Google Services JSON file is properly configured
- Verify that the notification channel is created

### iOS Issues
- Ensure APNs certificates are configured in Firebase Console
- Check that notification permissions are requested and granted
- Test on a physical device (push notifications don't work in simulator)

### General Issues
- Check Firebase console for any error messages
- Verify FCM tokens are being saved to Firestore
- Check device logs for notification-related errors

## Additional Features to Consider

1. **Notification Preferences**: Allow users to customize which notifications they receive
2. **Notification Sounds**: Add custom sounds for different notification types
3. **Notification Actions**: Add quick actions (e.g., "Mark as Complete" for tasks)
4. **Notification Grouping**: Group similar notifications together
5. **Rich Notifications**: Add images or custom layouts to notifications

## Notes

- The notification service is initialized in `main.dart` when the app starts
- Background message handling is set up for when app is in background/terminated
- Local notifications are used for scheduled reminders
- Push notifications are used for real-time events
- All notifications are saved to Firestore for persistence and viewing in the notifications screen
