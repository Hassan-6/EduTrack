// Example: Adding Notification Bell to Main Menu Header
// This code can be added to main_menu_screen.dart and ins_main_menu_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

// Add this widget to your header/AppBar
Widget buildNotificationBell(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<int>(
    stream: NotificationService().getUnreadCount(user.uid),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data ?? 0;
      
      return GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/notifications');
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

// Example usage in main menu header:
// Container(
//   height: 72,
//   padding: EdgeInsets.symmetric(horizontal: 24),
//   child: Row(
//     children: [
//       Text('EduTrack', style: ...),
//       Spacer(),
//       buildNotificationBell(context),  // <-- Add here
//       SizedBox(width: 16),
//       // Other header elements...
//     ],
//   ),
// )
