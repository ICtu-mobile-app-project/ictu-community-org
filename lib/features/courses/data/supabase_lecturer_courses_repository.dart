import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_delegate.dart';
import '../models/course_page.dart';
import '../models/course_student.dart';
import '../models/lecturer_course.dart';
import 'lecturer_courses_repository.dart';

class SupabaseLecturerCoursesRepository implements LecturerCoursesRepository {
  SupabaseLecturerCoursesRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<CoursePage> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String searchQuery = '',
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_my_courses',
      payload: <String, dynamic>{
        'page': page,
        'limit': limit,
        'search': searchQuery,
      },
    );

    final Map<String, dynamic> data = _asJsonMap(body['data']);
    final List<dynamic> rows = (data['items'] as List<dynamic>? ?? <dynamic>[]);

    return CoursePage(
      items: rows.map((dynamic row) => _mapCourse(_asJsonMap(row))).toList(),
      hasMore: data['hasMore'] == true,
    );
  }

  @override
  Future<bool> courseCodeExists(String courseCode) async {
    final CoursePage page = await getMyCourses(
      lecturerId: '',
      page: 0,
      limit: 50,
      searchQuery: courseCode,
    );

    final String normalized = courseCode.trim().toUpperCase();
    return page.items.any((LecturerCourse c) => c.courseCode == normalized);
  }

  @override
  Future<bool> canTeachDepartment({
    required String lecturerId,
    required String courseCode,
  }) async {
    if (courseCode.length < 3) {
      return false;
    }
    const Set<String> supported = <String>{'CSC', 'SEN', 'ICT', 'CYS', 'ISN'};
    return supported.contains(courseCode.substring(0, 3).toUpperCase());
  }

  @override
  Future<LecturerCourse> createCourse({
    required String lecturerId,
    required String lecturerName,
    required String courseCode,
    required String title,
    required String description,
    required String semester,
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'create_course',
      payload: <String, dynamic>{
        'courseCode': courseCode,
        'title': title,
        'description': description,
        'semester': semester,
      },
    );

    return _mapCourse(_asJsonMap(body['data']));
  }

  @override
  Future<LecturerCourse> getCourseDetails(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'get_course_details',
      payload: <String, dynamic>{'courseId': courseId},
    );

    return _mapCourse(_asJsonMap(body['data']));
  }

  @override
  Future<LecturerCourse> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String semester,
    required bool archived,
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'update_course',
      payload: <String, dynamic>{
        'courseId': courseId,
        'title': title,
        'description': description,
        'semester': semester,
        'archived': archived,
      },
    );

    return _mapCourse(_asJsonMap(body['data']));
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await _call(
      action: 'delete_course',
      payload: <String, dynamic>{'courseId': courseId},
    );
  }

  @override
  Future<List<CourseStudent>> getEnrolledStudents(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_students',
      payload: <String, dynamic>{'courseId': courseId},
    );

    final List<dynamic> rows =
        (_asJsonMap(body['data'])['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows
        .map((dynamic row) => _mapStudent(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<List<CourseStudent>> searchStudentsByEmail(String query) async {
    final Map<String, dynamic> body = await _call(
      action: 'search_students',
      payload: <String, dynamic>{'query': query},
    );

    final List<dynamic> rows =
        (_asJsonMap(body['data'])['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows
        .map((dynamic row) => _mapStudent(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<void> enrollStudents({
    required String courseId,
    required List<String> studentIds,
  }) async {
    await _call(
      action: 'add_students',
      payload: <String, dynamic>{
        'courseId': courseId,
        'studentIds': studentIds,
      },
    );
  }

  @override
  Future<void> removeStudent({
    required String courseId,
    required String studentId,
  }) async {
    await _call(
      action: 'remove_student',
      payload: <String, dynamic>{'courseId': courseId, 'studentId': studentId},
    );
  }

  @override
  Future<List<CourseDelegate>> getDelegates(String courseId) async {
    final Map<String, dynamic> body = await _call(
      action: 'list_delegates',
      payload: <String, dynamic>{'courseId': courseId},
    );

    final List<dynamic> rows =
        (_asJsonMap(body['data'])['items'] as List<dynamic>? ?? <dynamic>[]);

    return rows
        .map((dynamic row) => _mapDelegate(_asJsonMap(row)))
        .toList(growable: false);
  }

  @override
  Future<CourseDelegate> assignDelegate({
    required String courseId,
    required String studentId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'assign_delegate',
      payload: <String, dynamic>{
        'courseId': courseId,
        'studentId': studentId,
        'canUploadNotes': canUploadNotes,
        'canEditNotes': canEditNotes,
        'canDeleteNotes': canDeleteNotes,
      },
    );

    return _mapDelegate(_asJsonMap(body['data']));
  }

  @override
  Future<CourseDelegate> updateDelegatePermissions({
    required String courseId,
    required String delegateId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  }) async {
    final Map<String, dynamic> body = await _call(
      action: 'update_delegate',
      payload: <String, dynamic>{
        'courseId': courseId,
        'delegateId': delegateId,
        'canUploadNotes': canUploadNotes,
        'canEditNotes': canEditNotes,
        'canDeleteNotes': canDeleteNotes,
      },
    );

    return _mapDelegate(_asJsonMap(body['data']));
  }

  @override
  Future<void> removeDelegate({
    required String courseId,
    required String delegateId,
  }) async {
    await _call(
      action: 'remove_delegate',
      payload: <String, dynamic>{
        'courseId': courseId,
        'delegateId': delegateId,
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

    final Map<String, dynamic> body = _asJsonMap(response.data);
    if (response.status >= 400 || body['success'] == false) {
      throw Exception(_extractError(body));
    }

    return body;
  }

  Future<FunctionResponse> _invoke({
    required String action,
    required Map<String, dynamic> payload,
  }) {
    return _client.functions.invoke(
      'courses-api',
      body: <String, dynamic>{'action': action, ...payload},
    );
  }

  bool _isInvalidJwt(FunctionException error) {
    final String details = (error.details ?? '').toString().toLowerCase();
    return error.status == 401 && details.contains('invalid jwt');
  }

  Map<String, dynamic> _asJsonMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String && payload.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    throw const FormatException('Invalid function response payload.');
  }

  String _extractError(Map<String, dynamic> payload) {
    final dynamic top = payload['error'] ?? payload['message'];
    if (top is String && top.trim().isNotEmpty) {
      return top;
    }
    final dynamic data = payload['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nested = data['error'] ?? data['message'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested;
      }
    }
    return 'Courses request failed. Please try again.';
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

  CourseDelegate _mapDelegate(Map<String, dynamic> json) {
    return CourseDelegate(
      id: (json['id'] ?? '').toString(),
      studentId: (json['studentId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      studentEmail: (json['studentEmail'] ?? '').toString(),
      canUploadNotes: json['canUploadNotes'] == true,
      canEditNotes: json['canEditNotes'] == true,
      canDeleteNotes: json['canDeleteNotes'] == true,
    );
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
