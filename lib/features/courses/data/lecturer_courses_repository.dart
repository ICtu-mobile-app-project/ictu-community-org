import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_service.dart';
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
    final String userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return const <LecturerCourseOverview>[];
    }

    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final int from = page * limit;
        final int to = from + limit - 1;

        final String query = searchQuery?.trim().toLowerCase() ?? '';
        var request = _client
            .from('courses')
            .select('''
              id, 
              course_code, 
              title, 
              description,
              semester,
              created_at
            ''');

        if (query.isNotEmpty) {
          final String sanitized = query.replaceAll(',', ' ').replaceAll('%', '');
          request = request.or(
            'course_code.ilike.%$sanitized%,title.ilike.%$sanitized%',
          );
        }

        final List<dynamic> rows = await request
            .eq('lecturer_id', userId)
            .order('created_at', ascending: false)
            .range(from, to);
        
        // Fetch counts separately or join if schema allows
        // For simplicity and speed, let's map what we have and then enrich if needed
        // But since I updated the model, I should try to get counts.
        
        final List<LecturerCourseOverview> courses = [];
        for (var row in rows) {
          final courseId = row['id'];
          
          // Count students
          final studentsRes = await _client
              .from('course_enrollments')
              .select('id')
              .eq('course_id', courseId)
              .count(CountOption.exact);
          final studentsCount = studentsRes.count;

          // Count notes
          final notesRes = await _client
              .from('notes')
              .select('id')
              .eq('course_id', courseId)
              .count(CountOption.exact);
          final notesCount = notesRes.count;

          // Count alerts
          final alertsRes = await _client
              .from('alerts')
              .select('id')
              .eq('course_id', courseId)
              .count(CountOption.exact);
          final alertsCount = alertsRes.count;

          courses.add(LecturerCourseOverview(
            id: courseId,
            code: row['course_code'],
            title: row['title'],
            description: row['description'] ?? '',
            semester: row['semester'] ?? '',
            students: studentsCount,
            notes: notesCount,
            alerts: alertsCount,
            lastActivity: DateTime.tryParse(row['created_at'] ?? '') ?? DateTime.now(),
          ));
        }

        // Cache for offline use
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
  }

  Future<int> getMyCoursesCount() async {
    final String userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return 0;
    }

    final res = await _client
        .from('courses')
        .select('id')
        .eq('lecturer_id', userId)
        .count(CountOption.exact);

    return res.count;
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
