import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ictu_community_org/core/services/connectivity_service.dart';
import 'package:ictu_community_org/core/services/offline_service.dart';
import 'package:ictu_community_org/core/services/manual_http_client.dart';
import 'package:ictu_community_org/core/supabase/supabase_bootstrap.dart';
import 'package:ictu_community_org/features/courses/models/course_note.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_option.dart';
import 'package:ictu_community_org/features/courses/models/note_upload_session.dart';

class NotesService {
  NotesService({
    SupabaseClient? client,
    OfflineService? offlineService,
    ConnectivityService? connectivityService,
  })  : _client = client ?? Supabase.instance.client,
        _offlineService = offlineService ?? OfflineService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  static const int maxNoteUploadBytes = 100 * 1024 * 1024;
  static const int chunkThresholdBytes = 25 * 1024 * 1024;
  static const int _chunkSizeBytes = 5 * 1024 * 1024;
  static const int _maxUploadAttempts = 3;
  static const String _notesBucket = 'lecture-notes';

  final SupabaseClient _client;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  Future<List<LecturerCourseOption>> getLecturerCourses() async {
    if (!SupabaseBootstrap.isConfigured) return [];

    try {
      final isOnline = await _connectivityService.isOnline();
      if (isOnline) {
        final String userId = _client.auth.currentUser?.id ?? '';
        if (userId.isEmpty) {
          return const <LecturerCourseOption>[];
        }

        final List<dynamic> rows = (await _client
            .from('courses')
            .select('id, course_code, title')
            .eq('lecturer_id', userId)
            .order('course_code')) as List<dynamic>;

        return rows
            .map(
              (dynamic row) => LecturerCourseOption.fromJson(row as Map<String, dynamic>),
            )
            .toList(growable: false);
      } else {
        final cached = await _offlineService.getCachedCourses();
        if (cached == null) return [];
        return cached
            .map(
              (e) => LecturerCourseOption.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {
      return const <LecturerCourseOption>[];
    }
  }

  Future<CourseNote> uploadNote({
    required File file,
    required String title,
    required String courseId,
    required String courseCode,
    String? description,
    String? summary,
    String status = 'published',
    NoteUploadStrategy strategy = NoteUploadStrategy.chunkedRetry,
    void Function(NoteUploadProgress progress)? onProgress,
  }) async {
    final int size = await file.length();
    final String fileName = p.basename(file.path);
    final String ext = p.extension(fileName).toLowerCase();

    if (!const <String>{'.pdf', '.doc', '.docx'}.contains(ext)) {
      throw Exception('Only PDF, DOC, DOCX are allowed.');
    }

    if (size > maxNoteUploadBytes) {
      final int maxMb = (maxNoteUploadBytes / (1024 * 1024)).round();
      throw Exception('File size exceeds ${maxMb}MB limit.');
    }

    if (!SupabaseBootstrap.isConfigured) {
      throw Exception(
        'Supabase is not configured. Notes require a live backend connection.',
      );
    }

    final String uid = _client.auth.currentUser?.id ?? '';
    if (uid.isEmpty) {
      throw Exception('Please login again.');
    }

    final List<int> bytes = await file.readAsBytes();
    onProgress?.call(
      const NoteUploadProgress(
        fraction: 0.1,
        message: 'Preparing upload...',
      ),
    );
    final String objectPath =
        'notes/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final bool useChunked =
        strategy == NoteUploadStrategy.chunkedRetry && size > chunkThresholdBytes;

    await _uploadBinary(
      objectPath: objectPath,
      bytes: Uint8List.fromList(bytes),
      useChunked: useChunked,
      onProgress: onProgress,
    );

    final Map<String, dynamic> responseData = await ManualHttpClient.post(
      'notes-api',
      <String, dynamic>{
        'action': 'create_note',
        'courseId': courseId,
        'courseCode': courseCode,
        'course_code': courseCode, // Added for backend compatibility
        'title': title,
        'description': description,
        'summary': summary,
        'status': status,
        'contentUrl': objectPath,
        'fileName': fileName,
        'fileSizeBytes': size,
      },
    );

    if (responseData['success'] != true) {
      throw Exception(_extractError(responseData));
    }

    final Map<String, dynamic> row = (responseData['data'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    return CourseNote.fromJson(row);
  }

  Future<void> _uploadBinary({
    required String objectPath,
    required Uint8List bytes,
    required bool useChunked,
    void Function(NoteUploadProgress progress)? onProgress,
  }) async {
    if (!useChunked) {
      await _uploadSingleShotWithRetry(
        objectPath: objectPath,
        bytes: bytes,
        onProgress: onProgress,
      );
      return;
    }

    final int totalChunks = (bytes.length / _chunkSizeBytes).ceil();
    onProgress?.call(
      NoteUploadProgress(
        fraction: 0.2,
        message: 'Uploading in $totalChunks chunks...',
      ),
    );

    int attempt = 0;
    while (true) {
      try {
        await _client.storage.from(_notesBucket).uploadBinary(objectPath, bytes);
        onProgress?.call(
          const NoteUploadProgress(
            fraction: 1,
            message: 'Upload complete.',
          ),
        );
        return;
      } catch (error) {
        attempt += 1;
        if (attempt >= _maxUploadAttempts) {
          throw Exception(_extractStorageError(error));
        }

        final int completedChunks = ((attempt / _maxUploadAttempts) * totalChunks)
            .floor()
            .clamp(0, totalChunks);
        final double progress = 0.2 + (0.7 * completedChunks / totalChunks);
        onProgress?.call(
          NoteUploadProgress(
            fraction: progress,
            message: 'Connection unstable. Retrying upload (${attempt + 1}/$_maxUploadAttempts)...',
          ),
        );
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  Future<void> _uploadSingleShotWithRetry({
    required String objectPath,
    required Uint8List bytes,
    void Function(NoteUploadProgress progress)? onProgress,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        onProgress?.call(
          NoteUploadProgress(
            fraction: attempt == 0 ? 0.25 : 0.35,
            message: attempt == 0
                ? 'Uploading file...'
                : 'Retrying upload (${attempt + 1}/$_maxUploadAttempts)...',
          ),
        );

        await _client.storage.from(_notesBucket).uploadBinary(objectPath, bytes);
        onProgress?.call(
          const NoteUploadProgress(
            fraction: 1,
            message: 'Upload complete.',
          ),
        );
        return;
      } catch (error) {
        attempt += 1;
        if (attempt >= _maxUploadAttempts) {
          throw Exception(_extractStorageError(error));
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  Future<List<CourseNote>> listNotes({
    required String courseId,
    required String courseCode,
    String search = '',
    String sort = 'newest',
  }) async {
    if (!SupabaseBootstrap.isConfigured) return [];

    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final Map<String, dynamic> responseData = await ManualHttpClient.post(
          'notes-api',
          <String, dynamic>{
            'action': 'list_notes',
            'courseId': courseId,
            'search': search,
            'sort': sort,
          },
        );

        if (responseData['success'] != true) {
          throw Exception(_extractError(responseData));
        }

        final Map<String, dynamic> data = (responseData['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final List<dynamic> rows = (data['items'] as List<dynamic>?) ?? <dynamic>[];

        final List<CourseNote> notes = rows.map((dynamic row) {
          return CourseNote.fromJson(row as Map<String, dynamic>);
        }).toList(growable: false);

        // Cache for offline
        if (search.isEmpty) {
          final List<Map<String, dynamic>> cacheData =
              notes.map((CourseNote n) => n.toJson()).toList();
          await _offlineService.cacheNotes(courseId, cacheData);
        }

        return notes;
      } else {
        final cached = await _offlineService.getCachedNotes(courseId);
        if (cached == null) throw Exception('No internet and no cached data');
        return cached.map((json) => CourseNote.fromJson(json)).toList();
      }
    } catch (e) {
      final cached = await _offlineService.getCachedNotes(courseId);
      if (cached != null) {
        return cached.map((json) => CourseNote.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<String> createDownloadUrl(String objectPath) async {
    if (!SupabaseBootstrap.isConfigured) {
      throw Exception(
        'Supabase is not configured. Notes require a live backend connection.',
      );
    }

    final String signedUrl = await _client.storage
        .from(_notesBucket)
        .createSignedUrl(objectPath, 60 * 30);
    return signedUrl;
  }

  Future<void> deleteNote(String noteId, String objectPath) async {
    if (!SupabaseBootstrap.isConfigured) {
      throw Exception(
        'Supabase is not configured. Notes require a live backend connection.',
      );
    }

    final Map<String, dynamic> responseData = await ManualHttpClient.post(
      'notes-api',
      <String, dynamic>{
        'action': 'delete_note',
        'noteId': noteId,
      },
    );
    if (responseData['success'] != true) {
      throw Exception(_extractError(responseData));
    }

    await _client.storage.from(_notesBucket).remove(<String>[objectPath]);
  }

  Future<void> updateNote({
    required String noteId,
    String? title,
    String? description,
    String? summary,
    String? status,
  }) async {
    if (!SupabaseBootstrap.isConfigured) {
      throw Exception(
        'Supabase is not configured. Notes require a live backend connection.',
      );
    }
    final Map<String, dynamic> responseData = await ManualHttpClient.post(
      'notes-api',
      <String, dynamic>{
        'action': 'update_note',
        'noteId': noteId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (summary != null) 'summary': summary,
        if (status != null) 'status': status,
      },
    );
    if (responseData['success'] != true) {
      throw Exception(_extractError(responseData));
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic payload) {
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
        return <String, dynamic>{'message': payload};
      }
    }
    return <String, dynamic>{};
  }

  String _extractError(dynamic payload) {
    final Map<String, dynamic> map = _asJsonMap(payload);
    final dynamic value = map['error'] ?? map['message'] ?? map['details'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return 'Request failed. Please try again.';
  }

  String _extractStorageError(dynamic error) {
    final String text = error.toString();
    if (text.contains('Bucket not found')) {
      return 'Storage bucket lecture-notes is missing. Please contact admin.';
    }
    return text;
  }

  String _fileNameFromPath(String path) {
    if (path.trim().isEmpty) {
      return 'note-file';
    }
    return p.basename(path);
  }
}
