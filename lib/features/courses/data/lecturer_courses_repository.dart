<<<<<<< Updated upstream
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/lecturer_course_overview.dart';

class LecturerCoursesRepository {
  LecturerCoursesRepository({
    SupabaseClient? client,
    OfflineService? offlineService,
    ConnectivityService? connectivityService,
  })  : _client = client ?? Supabase.instance.client,
        _offlineService = offlineService ?? OfflineService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  final SupabaseClient _client;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  Future<List<LecturerCourseOverview>> getCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    if (!SupabaseBootstrap.isConfigured) {
      return _demoCourses;
    }

    final String userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return const <LecturerCourseOverview>[];
    }

    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final int from = page * limit;
        final int to = from + limit - 1;

        dynamic request = _client
            .from('courses')
            .select('''
              id, 
              course_code, 
              title, 
              description,
              semester,
              created_at,
              students_count:course_enrollments(count),
              notes_count:notes(count),
              alerts_count:alerts(count)
            ''')
            .eq('lecturer_id', userId)
            .order('created_at', ascending: false)
            .range(from, to);

        final String query = searchQuery?.trim().toLowerCase() ?? '';
        if (query.isNotEmpty) {
          final String sanitized = query.replaceAll(',', ' ').replaceAll('%', '');
          request = request.or(
            'course_code.ilike.%$sanitized%,title.ilike.%$sanitized%',
          );
        }

        final List<dynamic> rows = await request;
        final List<LecturerCourseOverview> courses = rows
            .map((dynamic row) => LecturerCourseOverview.fromJson(row))
            .toList(growable: false);

        // Cache for offline use (only if first page and no search for simplicity, or handle complex keys)
        if (page == 0 && query.isEmpty) {
          await _offlineService.cacheCourses(
            courses.map((c) => c.toJson()).toList(),
          );
        }

        return courses;
      } else {
        // Load from cache
        final cached = await _offlineService.getCachedCourses();
        if (cached == null) {
          throw Exception('No internet and no cached data');
        }
        return cached.map((json) => LecturerCourseOverview.fromJson(json)).toList();
      }
    } catch (e) {
      // If online request fails, try cache
      final cached = await _offlineService.getCachedCourses();
      if (cached != null) {
        return cached.map((json) => LecturerCourseOverview.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<void> createCourse({
    required String courseCode,
    required String title,
    required String semester,
    String description = '',
  }) async {
    if (!SupabaseBootstrap.isConfigured) {
      return;
    }

    final FunctionResponse response = await _client.functions.invoke(
      'courses-api',
      body: <String, dynamic>{
        'course_code': courseCode.trim().toUpperCase(),
        'title': title.trim(),
        'description': description.trim(),
        'semester': semester.trim(),
      },
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }

    final Map<String, dynamic>? payload = _asJsonMap(response.data);
    if (payload != null && payload['ok'] == false) {
      throw Exception(_extractError(payload));
    }

    clearCache();
  }

  Future<int> getMyCoursesCount() async {
    if (!SupabaseBootstrap.isConfigured) {
      return 0;
    }

    final String userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return 0;
    }

    final List<dynamic> rows = await _client
        .from('courses')
        .select('id')
        .eq('lecturer_id', userId);

    return rows.length;
  }

  void clearCache() {
    // No-op, _cache was removed in favor of OfflineService
  }

  Map<String, dynamic>? _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is String && data.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _extractError(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }

    final Map<String, dynamic>? data = _asJsonMap(payload);
    if (data != null) {
      final dynamic value = data['error'] ?? data['message'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return 'Unable to create course right now. Please try again.';
  }
}

class _CachedCoursesPage {
  _CachedCoursesPage({required this.data}) : timestamp = DateTime.now();

  final DateTime timestamp;
  final List<LecturerCourseOverview> data;

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

// Remove all demo/mock data for courses
final List<LecturerCourseOverview> _demoCourses = <LecturerCourseOverview>[];
=======
import '../models/course_delegate.dart';
import '../models/course_page.dart';
import '../models/course_student.dart';
import '../models/lecturer_course.dart';

abstract class LecturerCoursesRepository {
  Future<CoursePage> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String searchQuery = '',
  });

  Future<bool> courseCodeExists(String courseCode);

  Future<bool> canTeachDepartment({
    required String lecturerId,
    required String courseCode,
  });

  Future<LecturerCourse> createCourse({
    required String lecturerId,
    required String lecturerName,
    required String courseCode,
    required String title,
    required String description,
    required String semester,
  });

  Future<LecturerCourse> getCourseDetails(String courseId);

  Future<LecturerCourse> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String semester,
    required bool archived,
  });

  Future<void> deleteCourse(String courseId);

  Future<List<CourseStudent>> getEnrolledStudents(String courseId);

  Future<List<CourseStudent>> searchStudentsByEmail(String query);

  Future<void> enrollStudents({
    required String courseId,
    required List<String> studentIds,
  });

  Future<void> removeStudent({
    required String courseId,
    required String studentId,
  });

  Future<List<CourseDelegate>> getDelegates(String courseId);

  Future<CourseDelegate> assignDelegate({
    required String courseId,
    required String studentId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  });

  Future<CourseDelegate> updateDelegatePermissions({
    required String courseId,
    required String delegateId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  });

  Future<void> removeDelegate({
    required String courseId,
    required String delegateId,
  });
}
>>>>>>> Stashed changes
