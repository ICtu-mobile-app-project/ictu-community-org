# ICTU Community App - GitHub Copilot Implementation Guide
## Complete Feature Implementation Instructions

**Project:** The ICTU Community Mobile Application  
**University:** ICT University Yaoundé, Cameroon  
**Tech Stack:** Flutter (Frontend) + Supabase (Backend/Database) + Gladia API (AI Transcription)  
**Target Users:** 500+ concurrent users (students, lecturers, delegates)  
**Development Approach:** Feature-by-feature vertical integration

---

## 🎯 PROJECT CONTEXT

### About ICT University Yaoundé

**Academic Structure:**
- **Faculty:** Engineering & Technology (ICT Faculty)
- **Degree Programs:**
    - BSc ICT
    - BSc Computer Science
    - BSc Software Engineering
    - BSc Information Systems & Networking
      ## Repo at a glance
        - Flutter app (Dart) in `lib/`.
        - Supabase backend:
            - Edge Functions in `supabase/functions/*`.
            - DB schema/migrations in `supabase/migrations/`.
        - API contract + test logs live in `docs/api/`.

      ## App entry + navigation
        - Entrypoint: `lib/main.dart` initializes Supabase.
        - App shell: `lib/app.dart` → `SplashScreen`.
        - Primary in-app navigation: `lib/features/navigation/screens/main_shell.dart`.
            - Uses `ValueNotifier<int>` (`MainNavController`) + `NavigationBar`.

      ## Code organization (feature-first)
        - `lib/features/<feature>/screens/`: pages
        - `lib/features/<feature>/widgets/`: UI components
        - `lib/features/<feature>/controllers/`: state/actions (commonly `ValueNotifier`)
        - `lib/features/<feature>/data/`: API wrappers, repositories, storage helpers

      Shared code:
        - Supabase client accessor: `lib/core/supabase/supabase_instance.dart`.
        - Theme: `lib/core/theme/app_theme.dart`.

      ## Supabase + Edge Functions
        - Flutter calls functions via `SupabaseClient.functions.invoke('<name>', body: {...})`.
            - Auth: `lib/features/auth/data/auth_api.dart` invokes `register` and `login`.
            - Transcription: `lib/features/transcription/data/transcription_api.dart` invokes `transcribe-audio`.
        - Response parsing pattern: functions may return a JSON map **or** a JSON string.
            - See `_asJsonMap()` / `_extractError()` in `auth_api.dart` and `transcription_api.dart`.

      ## Auth session gotcha
      `AuthRepository` intentionally does **two steps**:
        1) Call Edge Function for domain-specific checks + payload.
        2) Establish a `supabase_flutter` auth session locally.

      This is required for Storage + any RLS-protected DB access.
      See: `lib/features/auth/data/auth_repository.dart`.

      ## Storage + transcription flow
        - Upload: `LectureUploadService` uploads to bucket `lecture-audio` and returns a bucket-relative object path.
        - Edge Function `transcribe-audio` expects `audioUrl` to be that **object path**, not a full URL.
            - Backend validates/normalizes `audioUrl` in `supabase/functions/transcribe-audio/index.ts`.

      ## Backend secrets
        - See `supabase/README_AUTH_FUNCTIONS.md`.
        - Edge Function secrets (server-side only):
            - `SUPABASE_URL`
            - `SUPABASE_SERVICE_ROLE_KEY` (never ship in Flutter)
            - `GLADIA_API_KEY` (for transcription)
            - Optional tuning: `GLADIA_BASE_URL`, `GLADIA_POLL_INTERVAL_MS`, `GLADIA_TIMEOUT_MS`

      ## Developer workflows (Windows / cmd.exe)
      ```bat
      cd /d S:\ictu-community-org
      flutter pub get
      flutter run
      ```
      ```bat
      flutter analyze
      dart format .
      flutter test
      ```
      ```bat
      flutter clean
      flutter pub get
      ```

      Deploy Edge Functions (Supabase CLI):
      ```bat
      supabase functions deploy register
      supabase functions deploy login
      supabase functions deploy transcribe-audio
      ```

      ## When changing APIs, update docs
        - Endpoint docs: `docs/api/endpoints/*.md`
        - Test logs: `docs/api/testing/*`
          }

      return null;
      }

  static int getYearLevel(String courseCode) {
  return int.parse(courseCode[3]);
  }

  static String getSemester(String courseCode) {
  final semesterCode = courseCode[4];
  switch (semesterCode) {
  case '1': return 'Fall';
  case '2': return 'Spring';
  case '3': return 'Summer';
  default: return 'Unknown';
  }
  }
  }
```

### 2. Email Validation

```dart
class ICTUEmailValidator {
  static final RegExp studentEmail = RegExp(
    r'^[a-zA-Z0-9._%+-]+@student\.ictu-university\.cm$'
  );
  
  static final RegExp lecturerEmail = RegExp(
    r'^[a-zA-Z0-9._%+-]+@ictu-university\.cm$'
  );
  
  static String? validate(String? email, {required bool isStudent}) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    if (isStudent) {
      if (!studentEmail.hasMatch(email)) {
        return 'Please use your ICTU student email (@student.ictu-university.cm)';
      }
    } else {
      if (!lecturerEmail.hasMatch(email)) {
        return 'Please use your ICTU staff email (@ictu-university.cm)';
      }
    }
    
    return null;
  }
  
  static UserRole getRoleFromEmail(String email) {
    if (email.contains('@student.')) {
      return UserRole.student;
    } else {
      return UserRole.lecturer;
    }
  }
}
```

### 3. Program & Faculty Constants

```dart
class ICTUConstants {
  static const String faculty = 'Engineering & Technology';
  
  static const List<String> programs = [
    'BSc ICT',
    'BSc Computer Science',
    'BSc Software Engineering',
    'BSc Information Systems & Networking',
    'BSc Cyber Security',
    'BSc Renewable Energy',
    'BSc Applied ICT in Journalism & Mass Communication',
  ];
  
  static const Map<int, String> yearLevels = {
    1: 'Year 1',
    2: 'Year 2',
    3: 'Year 3',
    4: 'Year 4',
  };
  
  static const List<String> semesters = [
    'Fall 2025',
    'Spring 2026',
    'Summer 2025',
  ];
  
  // Real courses for autocomplete/validation
  static const Map<String, String> sampleCourses = {
    'CSC1122': 'Algorithms and Data Structures I',
    'CSC1222': 'Algorithms and Data Structures II',
    'SEN3141': 'Software Design and Modelling',
    'SEN2142': 'Java Programming I',
    'SEN2242': 'Java Programming II',
    'ICT2111': 'Technical Writing for Engineers',
    'ICT3111': 'Relational Databases and Web Integration',
    'CYS4151': 'Ethical Hacking',
    'ISN3131': 'CCNA 1',
    'ISN3232': 'CCNA 2',
    'CSC4121': 'Artificial Intelligence',
    'SEN3142': 'Introduction to Mobile Application Development',
  };
}
```

---

## 🚀 PERFORMANCE OPTIMIZATION (500+ USERS)

### Pagination Implementation

```dart
class CoursesRepository {
  Future<List<Course>> getCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;
    
    var query = supabase
        .from('courses')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('course_code.ilike.%$searchQuery%,title.ilike.%$searchQuery%');
    }
    
    final data = await query;
    return data.map((json) => Course.fromJson(json)).toList();
  }
}
```

### Caching Strategy

```dart
class CacheManager {
  static const Duration cacheExpiry = Duration(hours: 1);
  
  Future<T?> getCached<T>(String key) async {
    final box = await Hive.openBox<CachedData>('app_cache');
    final cached = box.get(key);
    
    if (cached != null && !cached.isExpired) {
      return cached.data as T;
    }
    return null;
  }
  
  Future<void> cache<T>(String key, T data) async {
    final box = await Hive.openBox<CachedData>('app_cache');
    await box.put(key, CachedData(
      data: data,
      timestamp: DateTime.now(),
    ));
  }
}

// Usage
Future<List<Course>> getMyCourses() async {
  // Try cache first
  final cached = await cacheManager.getCached<List<Course>>('my_courses');
  if (cached != null) return cached;
  
  // Fetch from API
  final courses = await courseRepository.getMyCourses();
  
  // Cache result
  await cacheManager.cache('my_courses', courses);
  
  return courses;
}
```

### Debouncing Search

```dart
class SearchProvider extends ChangeNotifier {
  Timer? _debounce;
  
  void search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }
  
  Future<void> _performSearch(String query) async {
    isLoading = true;
    notifyListeners();
    
    final results = await courseRepository.searchCourses(query);
    
    searchResults = results;
    isLoading = false;
    notifyListeners();
  }
}
```

---

## 📱 NAVIGATION & ROUTING

### App Routes Configuration

```dart
class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Student
  static const String studentDashboard = '/student/dashboard';
  static const String myCourses = '/student/courses';
  static const String courseDetails = '/student/courses/:id';
  static const String lectureDetails = '/student/lectures/:id';
  static const String alertsList = '/student/alerts';
  static const String eventsList = '/student/events';
  
  // Lecturer
  static const String lecturerDashboard = '/lecturer/dashboard';
  static const String createCourse = '/lecturer/courses/create';
  static const String manageCourse = '/lecturer/courses/:id/manage';
  static const String recordLecture = '/lecturer/lectures/record';
  static const String createAlert = '/lecturer/alerts/create';
  
  // Shared
  static const String profile = '/profile';
  static const String settings = '/settings';
}

// Route Generator
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.studentDashboard:
      return MaterialPageRoute(builder: (_) => StudentDashboard());
    case AppRoutes.lecturerDashboard:
      return MaterialPageRoute(builder: (_) => LecturerDashboard());
    // ... other routes
    default:
      return MaterialPageRoute(builder: (_) => NotFoundScreen());
  }
}
```

---

## ⚠️ ERROR HANDLING (USER-FRIENDLY)

### Standard Error Messages

```dart
class AppErrors {
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505': // Unique violation
          return 'This record already exists';
        case '23503': // Foreign key violation
          return 'Related record not found';
        case 'PGRST116': // No rows found
          return 'Record not found';
        default:
          return 'A database error occurred. Please try again.';
      }
    }
    
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Incorrect email or password';
        case 'Email not confirmed':
          return 'Please verify your email before logging in';
        case 'User already registered':
          return 'An account with this email already exists';
        default:
          return error.message;
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}

// Usage
try {
  await authRepository.login(email, password);
} catch (e) {
  final message = AppErrors.getErrorMessage(e);
  showSnackBar(context, message, isError: true);
}
```

---

## 🎯 COPILOT INSTRUCTIONS FOR EACH FEATURE

When implementing features, Copilot should ALWAYS:

1. **Follow the color scheme and typography exactly**
2. **Use the glass card design for all containers**
3. **Implement proper role-based access control**
4. **Add pagination for lists (20 items per page)**
5. **Include loading states, error states, and empty states**
6. **Validate ICTU email formats and course codes**
7. **Update all 3 documentation files (API, UI Workflow, Feature Workflow)**
8. **Use ICTU-specific constants (programs, semesters, courses)**
9. **Implement caching for better performance**
10. **Add debouncing to search inputs**
11. **Include proper error handling with user-friendly messages**
12. **Ensure code works for 500+ concurrent users**
13. **Follow the project structure exactly**
14. **Use consistent spacing and component styles**
15. **Test with real ICTU data (course codes, lecturer names)**

---

## ✅ FEATURE COMPLETION CHECKLIST

For EVERY feature, ensure:

- [ ] Frontend UI implemented with consistent design
- [ ] Backend API/Edge Function created
- [ ] Database tables created with indexes
- [ ] Row Level Security (RLS) policies set
- [ ] Role-based permissions enforced
- [ ] Pagination implemented
- [ ] Caching implemented
- [ ] Loading states added
- [ ] Error states added
- [ ] Empty states added
- [ ] Input validation added
- [ ] API_ENDPOINTS.md updated
- [ ] UI_WORKFLOW.md updated
- [ ] FEATURE_WORKFLOW.md updated
- [ ] Tested with 50+ sample records
- [ ] Tested with all user roles

---

**This guide ensures consistency, scalability, and ICTU-specific customization across the entire app!**