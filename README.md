# EduTrack 🎓

**Your Academic Companion**

EduTrack is a comprehensive educational management application built with Flutter, designed to help students and instructors manage their academic life efficiently.

**Figma Link:** https://www.figma.com/design/qii3MjxwYE7bojDnczk2PB/EduTrack?node-id=0-1&t=ZkF63Eb4aiQybX0h-1

## 📱 Features

### For Students
- **Course Management**: View enrolled courses, track assignments, and monitor progress
- **Task & Assignment Tracking**: Create, manage, and complete academic tasks with due dates
- **Calendar Integration**: Visual calendar with events, assignments, and deadlines
- **Notes & Journal**: Create formatted notes with categories and maintain a personal journal
- **GPS-Enabled Camera**: Take location-tagged photos for assignments and submissions
- **Real-time Notifications**: Receive instant notifications for new assignments and announcements
- **Progress Monitoring**: Track course completion and assignment submission status

### For Instructors
- **Course Creation & Management**: Create and manage multiple courses with detailed information
- **Assignment Distribution**: Create and assign tasks to enrolled students
- **Student Monitoring**: Track student progress, activity, and submissions
- **Announcements**: Send notifications to all students in a course
- **Course Code Generation**: Generate unique 6-digit codes for course enrollment
- **Attendance Tracking**: Monitor student attendance and engagement

### General Features
- **Modern UI/UX**: Clean, responsive interface with light and dark theme support
- **Customizable Themes**: Multiple color schemes with gradient designs
- **Profile Management**: Update profile information and preferences
- **Search & Filter**: Advanced search and filtering across all features
- **Offline Support**: Work seamlessly with local data caching
- **Security**: Firebase authentication with role-based access control

## 🛠️ Technology Stack

### Frontend
- **Flutter 3.9.2**: Cross-platform mobile development framework
- **Dart SDK ^3.9.2**: Programming language
- **Provider**: State management
- **Google Fonts**: Typography (Inter font family)

### Backend & Services
- **Firebase Core**: Backend infrastructure
- **Firebase Authentication**: User authentication and authorization
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File and image storage
- **Firebase Cloud Messaging**: Push notifications

### Key Packages
- **table_calendar** (^3.0.9): Interactive calendar widget
- **camera** (^0.10.5): Camera functionality
- **geolocator** (^11.0.1): GPS location services
- **geocoding** (^2.1.1): Address geocoding
- **permission_handler** (^11.0.1): Device permissions management
- **sensors_plus** (^7.0.0): Device sensor access (compass, accelerometer)
- **intl** (^0.19.0): Internationalization and date formatting
- **shared_preferences** (^2.2.2): Local data persistence
- **flutter_local_notifications** (^17.2.3): Local notification handling

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models
│   ├── course.dart
│   ├── task.dart
│   ├── note.dart
│   └── journal_entry.dart
├── screens/                     # UI screens
│   ├── main_menu_screen.dart
│   ├── registration_screen.dart
│   ├── calendar_screen.dart
│   ├── courses_screen.dart
│   ├── tasks_screen.dart
│   ├── notes_screen.dart
│   └── profile_screen.dart
├── services/                    # Business logic & API
│   ├── firebase_service.dart
│   ├── auth_provider.dart
│   ├── notification_service.dart
│   ├── task_service.dart
│   ├── notes_service.dart
│   └── camera_location_service.dart
├── widgets/                     # Reusable components
│   ├── bottom_nav_bar.dart
│   ├── gradient_button.dart
│   ├── notification_bell.dart
│   └── gps_camera_screen.dart
└── utils/                       # Utilities & helpers
    ├── theme_provider.dart
    ├── route_manager.dart
    ├── calendar_event.dart
    └── text_formatter.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.9.2)
- Dart SDK (^3.9.2)
- Android Studio / VS Code with Flutter extension
- Firebase account with project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Hassan-6/EduTrack.git
   cd EduTrack
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and place it in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`
   - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Run the application**
   ```bash
   flutter run
   ```

### Firebase Setup

Enable the following Firebase services:
- **Authentication**: Email/Password provider
- **Firestore Database**: Create collections for users, courses, tasks, notes, calendar_events
- **Storage**: For storing images and files
- **Cloud Messaging**: For push notifications

### Required Permissions

The app requires the following permissions:
- **Camera**: For taking photos for verification
- **Location**: For GPS-tagged photos and attendance tracking
- **Notifications**: For receiving real-time updates
- **Storage**: For saving images and files

## 🎨 Features in Detail

### Course Management
- Create courses with titles, descriptions, and categories
- Set course schedules and meeting times
- Assign instructors and enroll students
- Track course progress and completion

### Assignment System
- Create tasks with titles, descriptions, and due dates
- Assign tasks to specific courses
- Set priority levels (High, Medium, Low)
- Mark assignments as complete
- Track submission status

### Notes & Journal
- Create formatted notes with bold, italic, and list formatting
- Organize notes by categories (Personal, Course-specific)
- Maintain daily journal entries
- Search and filter notes
- Favorite important entries

### Calendar
- Visual month view with color-coded events
- Multiple event types: Assignment, Quiz, Exam, Lecture, Event
- Add recurring events
- View upcoming deadlines
- Day-specific event lists

### Notifications
- Real-time push notifications for new assignments
- In-app notification center with unread badges
- Notification history and management
- Custom notification sounds and preferences

## 🎯 User Roles

### Student
- Enroll in courses via unique 6-digit codes
- View assigned tasks and deadlines
- Submit attendance with location tags
- Track personal progress
- Receive instructor notifications

### Instructor
- Create and manage courses
- Assign tasks to students
- Monitor student activity and progress
- Send announcements to enrolled students
- Generate course enrollment QR codes

## 🔐 Security

- Firebase Authentication for secure user management
- Role-based access control (Student/Instructor)
- Firestore security rules for data protection
- Secure file upload with validation
- Permission-based feature access

## 📱 Platform Support

- ✅ Android (minSdkVersion 21, targetSdkVersion 34)
- ✅ iOS (deployment target: iOS 12.0+)
- ⏳ Web (partial support)
- ⏳ Windows/macOS/Linux (in development)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is developed for educational purposes.

## 👨‍💻 Developer

**Ghulam Hassan**
- GitHub: [@Hassan-6](https://github.com/Hassan-6)

**Oneeb Tariq**
- GitHub: [@Raiden216](https://github.com/Raiden216)

## 📞 Support

For support, questions, or feature requests, please open an issue on GitHub.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Fonts for typography
- The open-source community for various packages used in this project

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Status**: Active Development
