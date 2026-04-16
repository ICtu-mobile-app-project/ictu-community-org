import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_service.dart';
import '../models/course_note.dart';
import 'course_notes_repository.dart';

class SupabaseCourseNotesRepository implements CourseNotesRepository {
  SupabaseCourseNotesRepository({SupabaseClient? client, OfflineService? offlineService})
    : _client = client ?? Supabase.instance.client,
      _offlineService = offlineService ?? OfflineService();

  final SupabaseClient _client;
  final OfflineService _offlineService;

  @override
  Future<List<CourseNote>> listNotes({
    required String courseId,
    String searchQuery = '',
    String sort = 'newest',
  }) async {
    try {
      final Map<String, dynamic> response = await _call(
        action: 'list_notes',
        payload: <String, dynamic>{
          'courseId': courseId,
          'search': searchQuery,
          'sort': sort,
        },
      );

      final List<dynamic> rows =
          (_asJsonMap(response['data'])['items'] as List<dynamic>? ??
          <dynamic>[]);

      final notes = rows
          .map((dynamic row) => _mapNote(_asJsonMap(row)))
          .toList(growable: false);

      // Cache notes if it's a full list (no search)
      if (searchQuery.isEmpty) {
        await _offlineService.cacheNotes(courseId, notes.map((e) => e.toJson()).toList());
      }

      return notes;
    } catch (e) {
      // Fallback to cache on error
      final cached = await _offlineService.getCachedNotes(courseId);
      if (cached != null) {
        return cached.map((e) => CourseNote.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  @override
  Future<CourseNote> createNote({
    required String courseId,
    required String title,
    required String description,
    required String contentUrl,
    required String fileName,
    required int fileSizeBytes,
  }) async {
    final Map<String, dynamic> response = await _call(
      action: 'create_note',
      payload: <String, dynamic>{
        'courseId': courseId,
        'title': title,
        'description': description,
        'contentUrl': contentUrl,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
      },
    );

    return _mapNote(_asJsonMap(response['data']));
  }

  @override
  Future<CourseNote> updateNoteTitle({
    required String noteId,
    required String newTitle,
  }) async {
    final Map<String, dynamic> response = await _call(
      action: 'update_note_title',
      payload: <String, dynamic>{'noteId': noteId, 'title': newTitle},
    );

    return _mapNote(_asJsonMap(response['data']));
  }

  @override
  Future<void> deleteNote({required String noteId}) async {
    await _call(
      action: 'delete_note',
      payload: <String, dynamic>{'noteId': noteId},
    );
  }

  @override
  Future<String> createDownloadUrl({required String noteId}) async {
    final Map<String, dynamic> response = await _call(
      action: 'create_download_url',
      payload: <String, dynamic>{'noteId': noteId},
    );

    return (_asJsonMap(response['data'])['downloadUrl'] ?? '').toString();
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
      'notes-api',
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

    return 'Notes request failed. Please try again.';
  }

  CourseNote _mapNote(Map<String, dynamic> json) {
    return CourseNote(
      id: (json['id'] ?? '').toString(),
      courseId: (json['courseId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      contentUrl: (json['contentUrl'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      fileSizeBytes: _toInt(json['fileSizeBytes']),
      uploadedBy: (json['uploadedBy'] ?? '').toString(),
      uploadedByName: (json['uploadedByName'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
