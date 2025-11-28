class RouteManager {
  static String _currentUserType = 'student';
  
  static void setUserType(String userType) {
    _currentUserType = userType;
  }
  
  static String getUserType() {
    return _currentUserType;
  }
  
  // Main menus
  static String getMainMenuRoute() {
    return _currentUserType == 'instructor' 
        ? '/ins_main_menu' 
        : '/main_menu';
  }
  
  // Courses
  static String getCoursesRoute() {
    return _currentUserType == 'instructor' 
        ? '/ins_courses' 
        : '/courses';
  }
  
  // Course Detail
  static String getCourseDetailRoute() {
    return _currentUserType == 'instructor' 
        ? '/ins_course_detail' 
        : '/course_detail';
  }
  
  // Archived Courses
  static String getArchivedCoursesRoute() => '/archived_courses';
  
  // Shared features - same for both user types
  static String getToDoListRoute() => '/todo';
  static String getCalendarRoute() => '/calendar';
  static String getNotesRoute() => '/notes';
  static String getQnARoute() => '/qna';
  static String getProfileRoute() => '/profile';
  
  // Attendance - different for instructor and student
  static String getAttendanceRoute() {
    return _currentUserType == 'instructor' 
        ? '/ins_attendance' 
        : '/attendance';
  }
  
  // Instructor-specific features
  static String getPresentQuestionRoute() => '/present_question';
  static String getScheduleQuizRoute() => '/schedule_quiz';
  static String getQuestionResultsRoute() => '/question_results';
  
  // Student-specific features
  static String getCourseEnrollmentRoute() => '/course_enrollment';
  static String getPopupQuestionRoute() => '/popup_question';
  static String getQuizRoute() => '/quiz';
}