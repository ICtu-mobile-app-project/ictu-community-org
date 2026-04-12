import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/lecturer_course_overview.dart';

class LecturerCoursesRepository {
  LecturerCoursesRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const Duration _cacheExpiry = Duration(hours: 1);
  static final Map<String, _CachedCoursesPage> _cache =
      <String, _CachedCoursesPage>{};

  final SupabaseClient _client;

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

    final String query = searchQuery?.trim().toLowerCase() ?? '';
    final String key = '$userId:$page:$limit:$query';

    final _CachedCoursesPage? cached = _cache[key];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    final int from = page * limit;
    final int to = from + limit - 1;

    dynamic request = _client
        .from('courses')
        .select('id, course_code, title, created_at')
        .eq('lecturer_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

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

    _cache[key] = _CachedCoursesPage(data: courses);
    return courses;
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
    _cache.clear();
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
      DateTime.now().difference(timestamp) > LecturerCoursesRepository._cacheExpiry;
}

final List<LecturerCourseOverview> _demoCourses = <LecturerCourseOverview>[
  LecturerCourseOverview(
    id: 'demo-course-1',
    code: 'SEN3141',
    title: 'Software Design and Modelling',
    students: 74,
    lectures: 18,
    lastActivity: DateTime(2026, 4, 11),
  ),
  LecturerCourseOverview(
    id: 'demo-course-2',
    code: 'ICT2111',
    title: 'Technical Writing for Engineers',
    students: 52,
    lectures: 9,
    lastActivity: DateTime(2026, 4, 10),
  ),
];

