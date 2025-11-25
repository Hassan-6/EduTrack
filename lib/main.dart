// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/ins_main_menu_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/to_do_list_screen.dart';
import 'screens/qna_wall_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/course_enrollment_screen.dart';
import 'screens/ins_courses_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/ins_course_detail_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/ins_attendance_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_viewer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/new_entry_screen.dart';
import 'screens/new_task_screen.dart';
import 'screens/popup_question_screen.dart';
import 'screens/present_question_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/question_results_screen.dart';
import 'screens/schedule_quiz_screen.dart';
import 'widgets/course_model.dart';
import 'utils/theme_provider.dart';
import 'services/firebase_service.dart';
import 'services/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return MaterialApp(
            title: 'EduTrack',
            theme: _buildLightTheme(themeProvider),
            darkTheme: _buildDarkTheme(themeProvider),
            themeMode: themeProvider.themeMode,
            home: _buildHome(authProvider),
            routes: {
              '/registration': (context) => const AuthScreen(),
              '/main_menu': (context) => const MainMenuScreen(),
              '/ins_main_menu': (context) => const InstructorMainMenuScreen(),
              '/notes': (context) => const NotesScreen(),
              '/new_entry': (context) => const AddEntryScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/todo': (context) => const TodoListScreen(),
              '/new_task': (context) => const NewTaskScreen(),
              '/qna': (context) => const QAWallScreen(),
              '/courses': (context) => const CoursesScreen(),
              '/course_detail': (context) {
                final course = ModalRoute.of(context)!.settings.arguments as Course;
                return CourseDetailScreen(course: course);
              },
              '/course_enrollment': (context) => const CourseEnrollmentScreen(),
              '/ins_courses': (context) => const InstructorCoursesScreen(),
              '/ins_course_detail': (context) {
                final course = ModalRoute.of(context)!.settings.arguments as Course;
                return InstructorCourseDetailScreen(course: course);
              },
              '/attendance': (context) => const AttendanceScreen(),
              '/ins_attendance': (context) => const InsAttendanceScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/profile_viewer': (context) => ProfileViewerScreen(
                    userProfile: ModalRoute.of(context)!.settings.arguments as UserProfile,
                  ),
              '/settings': (context) => const SettingsScreen(),
              '/popup_question': (context) {
                final courseName = ModalRoute.of(context)!.settings.arguments as String;
                return PopupQuestionScreen(courseName: courseName);
              },
              '/quiz': (context) => const QuizScreen(),
              '/present_question': (context) {
                final course = ModalRoute.of(context)!.settings.arguments as Course;
                return PresentQuestionScreen(course: course);
              },
              '/schedule_quiz': (context) {
                final course = ModalRoute.of(context)!.settings.arguments as Course;
                return ScheduleQuizScreen(course: course);
              },
              '/question_results': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return QuestionResultsScreen(
                  course: args['course'],
                  question: args['question'],
                  questionType: args['questionType'],
                  options: args['options'],
                  correctAnswerIndex: args['correctAnswerIndex'],
                );
              },
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  /// Build home screen based on authentication state
  Widget _buildHome(AuthProvider authProvider) {
    if (authProvider.isLoading) {
      // Show splash/loading screen while checking authentication
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F5e6b0cb1-e8f3-4a4f-bfcc-06d7ffd7be20.png',
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, size: 80);
                },
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4E9FEC)),
              ),
            ],
          ),
        ),
      );
    }

    // User is logged in - show appropriate home screen
    if (authProvider.isAuthenticated) {
      if (authProvider.userType == 'instructor') {
        return const InstructorMainMenuScreen();
      } else {
        return const MainMenuScreen();
      }
    }

    // User is not logged in - show registration screen
    return const AuthScreen();
  }

  ThemeData _buildLightTheme(ThemeProvider themeProvider) {
    final baseTheme = ThemeData.light();
    return baseTheme.copyWith(
      primaryColor: themeProvider.primaryColor,
      colorScheme: ColorScheme.light(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
        background: const Color(0xFFF8FAFC),
        surface: Colors.white,
        onBackground: const Color(0xFF1F2937),
        onSurface: const Color(0xFF1F2937),
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      dividerColor: const Color(0xFFF3F4F6),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme(ThemeProvider themeProvider) {
    final baseTheme = ThemeData.dark();
    return baseTheme.copyWith(
      primaryColor: themeProvider.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: themeProvider.primaryColor,
        secondary: themeProvider.secondaryColor,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        onBackground: Colors.white,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      dividerColor: const Color(0xFF374151),
      useMaterial3: true,
    );
  }
}