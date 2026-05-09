# Frontend UI Mapping

Mapping of screens, widgets, and themes within the Flutter application.

## Core Structure
- `lib/main.dart`: Entry point of the application.
- `lib/app.dart`: Main App widget and routing configuration.
- `lib/core/theme/`: UI styling, colors, and typography.
- `lib/core/widgets/`: Shared reusable widgets.

## Feature Screens

### Authentication
- `lib/features/auth/screens/splash_screen.dart`: Initial loading screen.
- `lib/features/auth/screens/welcome_screen.dart`: Role selection and feature overview.
- `lib/features/auth/screens/login_screen.dart`: User login.
- `lib/features/auth/screens/signup_screen.dart`: New user registration.

### Home & Navigation
- `lib/features/navigation/screens/main_shell.dart`: Bottom navigation layout.
- `lib/features/home/screens/home_dashboard_screen.dart`: Student dashboard.
- `lib/features/home/screens/lecturer_home_dashboard_screen.dart`: Lecturer dashboard.
- `lib/features/home/screens/admin_home_dashboard_screen.dart`: Admin dashboard.

### Courses & Management
- `lib/features/courses/screens/enrolled_courses_screen.dart`: List of student's courses.
- `lib/features/courses/screens/course_details_screen.dart`: Detailed view of a course.
- `lib/features/courses/screens/course_search_screen.dart`: Search and enroll in courses.
- `lib/features/courses/screens/lecturer_my_courses_screen.dart`: Courses managed by a lecturer.
- `lib/features/courses/screens/lecturer_course_details_screen.dart`: Management view for lecturers.
- `lib/features/courses/screens/create_course_screen.dart`: Interface for creating new courses.
- `lib/features/courses/screens/timetable_screen.dart`: Schedule view.
- `lib/features/courses/screens/upload_notes_screen.dart`: Interface for uploading lecture notes.
- `lib/features/courses/screens/course_notes_list_screen.dart`: List of notes for a course.

### Alerts & Notifications
- `lib/features/alerts/screens/lecturer_alerts_list_screen.dart`: Alerts managed by lecturer.
- `lib/features/alerts/screens/create_alert_screen.dart`: Create a new alert.
- `lib/features/notifications/screens/notifications_screen.dart`: General notification inbox.

### Miscellaneous
- `lib/features/news/screens/campus_news_screen.dart`: Campus updates and news.
- `lib/features/community/screens/community_feed_screen.dart`: Community interaction hub.
- `lib/features/profile/screens/profile_screen.dart`: User profile and settings.
- `lib/features/transcription/screens/audio_ai_transcription_screen.dart`: AI-powered lecture transcription.
