import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ictu_community_org/core/services/connectivity_service.dart';
import 'package:ictu_community_org/core/services/offline_service.dart';
import 'package:ictu_community_org/core/services/manual_http_client.dart';
import 'package:ictu_community_org/features/courses/models/course_delegate.dart';
import 'package:ictu_community_org/features/courses/models/course_student.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';

class SupabaseLecturerCoursesRepository implements LecturerCoursesRepository {
  SupabaseLecturerCoursesRepository({
    SupabaseClient? client,
    OfflineService? offlineService,
    ConnectivityService? connectivityService,
  })  : _client = client ?? Supabase.instance.client,
        _offlineService = offlineService ?? OfflineService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  final SupabaseClient _client;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  @override
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
        
        var request = _client.from('courses').select('''
              id, 
              course_code, 
              title, 
              description,
              semester,
              created_at,
              course_enrollments(count),
              notes(count),
              alerts(count)
            ''');

        if (query.isNotEmpty) {
          final String sanitized = query.replaceAll(',', ' ').replaceAll('%', '');
          request = request.or(
            'course_code.ilike.%$sanitized%,title.ilike.%$sanitized%',
          );
        }

        final List<dynamic> rows = (await request
            .eq('lecturer_id', userId)
            .order('created_at', ascending: false)
            .range(from, to)) as List<dynamic>;

        final List<LecturerCourseOverview> courses = rows.map((dynamic row) {
          final Map<String, dynamic> rowMap = row as Map<String, dynamic>;
          final List<dynamic> enrollments = (rowMap['course_enrollments'] as List<dynamic>? ?? <dynamic>[]);
          final List<dynamic> notes = (rowMap['notes'] as List<dynamic>? ?? <dynamic>[]);
          final List<dynamic> alerts = (rowMap['alerts'] as List<dynamic>? ?? <dynamic>[]);

          return LecturerCourseOverview(
            id: (rowMap['id'] ?? '').toString(),
            code: (rowMap['course_code'] ?? '').toString(),
            title: (rowMap['title'] ?? '').toString(),
            description: (rowMap['description'] ?? '').toString(),
            semester: (rowMap['semester'] ?? '').toString(),
            students: enrollments.isNotEmpty ? (enrollments.first as Map<String, dynamic>)['count'] as int? ?? 0 : 0,
            notes: notes.isNotEmpty ? (notes.first as Map<String, dynamic>)['count'] as int? ?? 0 : 0,
            alerts: alerts.isNotEmpty ? (alerts.first as Map<String, dynamic>)['count'] as int? ?? 0 : 0,
            lastActivity: DateTime.tryParse((rowMap['created_at'] ?? '').toString()) ?? DateTime.now(),
          );
        }).toList();

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

  @override
  Future<LecturerCoursesResult> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_my_courses',
      payload: <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': searchQuery ?? '',
      },
    );

    final Map<String, dynamic>? data = _asJsonMap(body['data']);
    final List<dynamic> rows = (data?['items'] as List<dynamic>? ?? <dynamic>[]);
    final bool hasMore = data?['hasMore'] == true;

    final List<LecturerCourse> items = rows.map((dynamic row) {
      return _mapCourse(_asJsonMap(row) ?? {});
    }).toList();

    return LecturerCoursesResult(
      items: items,
      hasMore: hasMore,
    );
  }

  @override
  Future<void> createCourse({
    required String lecturerId,
    required String courseCode,
    required String title,
    required String semester,
    String description = '',
  }) async {
    await _call(
      action: 'create_course',
      payload: <String, dynamic>{
        'courseCode': courseCode.trim().toUpperCase(),
        'title': title.trim(),
        'description': description.trim(),
        'semester': semester.trim(),
      },
    );
  }

  @override
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

  Future<LecturerCourse> getCourseDetails(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'get_course_details',
      payload: <String, dynamic>{'courseId': courseId},
    );

    final Map<String, dynamic>? data = _asJsonMap(body['data']);
    if (data == null) {
      throw Exception('Course details not found');
    }
    return _mapCourse(data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _call(
      action: 'delete_course',
      payload: <String, dynamic>{'courseId': courseId},
    );
  }

  Future<List<CourseStudent>> getEnrolledStudents(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_students',
      payload: <String, dynamic>{'courseId': courseId},
    );

    final Map<String, dynamic>? data = _asJsonMap(body['data']);
    final List<dynamic> rows = (data?['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows
        .map((dynamic row) => _mapStudent(_asJsonMap(row) ?? {}))
        .toList(growable: false);
  }

  @override
  Future<List<CourseDelegate>> getDelegates(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_delegates',
      payload: <String, dynamic>{'courseId': courseId},
    );

    final Map<String, dynamic>? data = _asJsonMap(body['data']);
    final List<dynamic> rows = (data?['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows.map((dynamic row) {
      final Map<String, dynamic> rowMap = _asJsonMap(row) ?? <String, dynamic>{};
      return _mapDelegateJson(rowMap);
    }).toList(growable: false);
  }

  @override
  Future<List<CourseStudent>> searchStudents(String query) async {
    final Map<String, dynamic> body = await _call(
      action: 'search_students',
      payload: <String, dynamic>{'query': query},
    );

    final Map<String, dynamic>? data = _asJsonMap(body['data']);
    final List<dynamic> rows = (data?['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows
        .map((dynamic row) => _mapStudent(_asJsonMap(row) ?? {}))
        .toList(growable: false);
  }

  @override
  Future<void> assignDelegate({
    required String courseId,
    required String studentId,
  }) async {
    await _call(
      action: 'assign_delegate',
      payload: <String, dynamic>{
        'courseId': courseId,
        'studentId': studentId,
      },
    );
  }

  @override
  Future<void> removeDelegate({
    required String courseId,
    required String studentId,
  }) async {
    await _call(
      action: 'remove_delegate',
      payload: <String, dynamic>{
        'courseId': courseId,
        'studentId': studentId,
      },
    );
  }


  Future<Map<String, dynamic>> _call({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    FunctionResponse response;
    try {
      response = await _invoke(action: action, payload: payload);
    } on FunctionException catch (error) {
      if (!_isInvalidJwt(error)) {
        rethrow;
      }

      final AuthResponse refresh = await _client.auth.refreshSession();
      final String refreshedToken =
          refresh.session?.accessToken ??
          _client.auth.currentSession?.accessToken ??
          '';
      if (refreshedToken.isEmpty) {
        throw Exception('Your session expired. Please log in again.');
      }
      response = await _invoke(action: action, payload: payload);
    }

    final Map<String, dynamic> body = _asJsonMap(response.data) ?? <String, dynamic>{};
    if (response.status >= 400 || body['success'] == false) {
      throw Exception(_extractError(body));
    }

    return body;
  }

  Future<FunctionResponse> _invoke({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    // Using manual HTTP client to bypass supabase_flutter body-stripping bug
    final responseBody = await ManualHttpClient.post(
      'courses-api',
      <String, dynamic>{'action': action, ...payload},
    );
    
    // Wrap in FunctionResponse to maintain compatibility with existing code
    return FunctionResponse(
      data: responseBody,
      status: 200, // ManualHttpClient throws on error, so 200 is safe here
    );
  }

  bool _isInvalidJwt(FunctionException error) {
    final String details = (error.details ?? '').toString().toLowerCase();
    return error.status == 401 && details.contains('invalid jwt');
  }

  Map<String, dynamic>? _asJsonMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String && payload.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(payload);
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

    return 'Unable to process course request right now.';
  }

  LecturerCourse _mapCourse(Map<String, dynamic> json) {
    return LecturerCourse(
      id: (json['id'] ?? '').toString(),
      courseCode: (json['courseCode'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      semester: (json['semester'] ?? '').toString(),
      lecturerId: (json['lecturerId'] ?? '').toString(),
      lecturerName: (json['lecturerName'] ?? '').toString(),
      studentCount: _asInt(json['studentCount']),
      lectureCount: _asInt(json['lectureCount']),
      notesCount: _asInt(json['notesCount']),
      alertCount: _asInt(json['alertCount']),
      archived: json['archived'] == true,
      lastActivity:
          DateTime.tryParse((json['lastActivity'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  CourseStudent _mapStudent(Map<String, dynamic> json) {
    return CourseStudent(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      enrolledAt:
          DateTime.tryParse((json['enrolledAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  CourseDelegate _mapDelegateJson(Map<String, dynamic> json) {
    return CourseDelegate(
      id: (json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      studentEmail: (json['studentEmail'] ?? '').toString(),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
