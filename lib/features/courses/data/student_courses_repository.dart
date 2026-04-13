import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/student_course_overview.dart';

class StudentCoursesRepository {
  StudentCoursesRepository({
    SupabaseClient? client,
    OfflineService? offlineService,
    ConnectivityService? connectivityService,
  })  : _client = client ?? Supabase.instance.client,
        _offlineService = offlineService ?? OfflineService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  final SupabaseClient _client;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  Future<List<StudentCourseOverview>> getAvailableCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
  }) async {
    if (!SupabaseBootstrap.isConfigured) return [];

    try {
      final isOnline = await _connectivityService.isOnline();
      if (isOnline) {
        final response = await _client.functions.invoke(
          'student-course-api',
          body: {
            'action': 'list_available_courses',
            'search': searchQuery,
            'page': page,
            'limit': limit,
          },
        );

        if (response.status >= 400) {
          throw Exception(_extractError(response.data));
        }

        final Map<String, dynamic> payload = _asJsonMap(response.data);
        final List<dynamic> rows = payload['courses'] ?? [];
        return rows.map((json) => StudentCourseOverview.fromJson(json)).toList();
      } else {
        // We don't typically cache all available courses, but we could.
        // For now, if offline and searching/listing available, return empty or throw.
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<StudentCourseOverview>> getMyCourses() async {
    if (!SupabaseBootstrap.isConfigured) return [];

    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final response = await _client.functions.invoke(
          'student-course-api',
          body: {
            'action': 'list_my_courses',
          },
        );

        if (response.status >= 400) {
          throw Exception(_extractError(response.data));
        }

        final Map<String, dynamic> payload = _asJsonMap(response.data);
        final List<dynamic> rows = payload['courses'] ?? [];

        final courses = rows.map((json) {
          final map = Map<String, dynamic>.from(json);
          map['is_enrolled'] = true;
          return StudentCourseOverview.fromJson(map);
        }).toList();

        // Cache for offline use
        await _offlineService.cacheCourses(
          courses.map((c) => c.toJson()).toList(),
        );

        return courses;
      } else {
        // Load from cache
        final cached = await _offlineService.getCachedCourses();
        if (cached == null) {
          throw Exception('No internet and no cached data');
        }
        return cached.map((json) => StudentCourseOverview.fromJson(json)).toList();
      }
    } catch (e) {
      // If online request fails, try cache
      final cached = await _offlineService.getCachedCourses();
      if (cached != null) {
        return cached.map((json) => StudentCourseOverview.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    final response = await _client.functions.invoke(
      'student-course-api',
      body: {
        'action': 'enroll_in_course',
        'course_id': courseId,
      },
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }
  }

  Future<Map<String, dynamic>> getCourseContent(String courseId, String courseCode) async {
    final response = await _client.functions.invoke(
      'student-course-api',
      body: {
        'action': 'get_course_content',
        'course_id': courseId,
        'course_code': courseCode,
      },
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }

    return _asJsonMap(response.data);
  }

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {}
    }
    return {};
  }

  String _extractError(dynamic data) {
    final map = _asJsonMap(data);
    return map['error'] ?? map['message'] ?? 'An error occurred';
  }
}
