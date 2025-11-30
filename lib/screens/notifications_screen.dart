// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/theme_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, themeProvider),
            
            // Notifications List
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: _notificationService.getUserNotifications(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading notifications',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(
                        context,
                        themeProvider,
                        notifications[index],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider themeProvider) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : const Color(0x0C000000),
            spreadRadius: 0,
            offset: const Offset(0, 1),
            blurRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 86,
              height: 32,
              decoration: BoxDecoration(
                gradient: themeProvider.gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Title with unread count
          StreamBuilder<int>(
            stream: user != null ? _notificationService.getUnreadCount(user.uid) : const Stream.empty(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          
          const Spacer(),
          
          // Placeholder for alignment
          const SizedBox(width: 86),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    ThemeProvider themeProvider,
    AppNotification notification,
  ) {
    return GestureDetector(
      onTap: () async {
        if (!notification.isRead) {
          await _notificationService.markAsRead(notification.id);
        }
        _handleNotificationTap(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).cardColor
              : Theme.of(context).primaryColor.withOpacity(0.05),
          border: Border.all(
            color: notification.isRead
                ? Theme.of(context).dividerColor
                : Theme.of(context).primaryColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: themeProvider.gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.todoReminder:
        return Icons.task_alt;
      case NotificationType.calendarReminder:
        return Icons.calendar_today;
      case NotificationType.qnaResponse:
        return Icons.question_answer;
      case NotificationType.questionPresented:
        return Icons.quiz;
      case NotificationType.quizScheduled:
        return Icons.assignment;
      case NotificationType.enrollmentRequest:
        return Icons.person_add;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.todoReminder:
        Navigator.pushNamed(context, '/todo-list');
        break;
      case NotificationType.calendarReminder:
        Navigator.pushNamed(context, '/calendar');
        break;
      case NotificationType.qnaResponse:
        Navigator.pushNamed(context, '/qna-wall');
        break;
      case NotificationType.questionPresented:
      case NotificationType.quizScheduled:
        Navigator.pushNamed(context, '/courses');
        break;
      case NotificationType.enrollmentRequest:
        Navigator.pushNamed(context, '/instructor-courses');
        break;
    }
  }
}
