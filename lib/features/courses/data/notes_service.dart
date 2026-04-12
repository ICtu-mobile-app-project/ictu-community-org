import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/course_note.dart';
import '../models/note_upload_session.dart';

class NotesService {
  NotesService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const int maxNoteUploadBytes = 100 * 1024 * 1024;
  static const int _chunkSizeBytes = 5 * 1024 * 1024;
  static const int _maxUploadAttempts = 3;

  final SupabaseClient _client;

  Future<List<LecturerCourseOption>> getLecturerCourses() async {
    if (!SupabaseBootstrap.isConfigured) {
      return const <LecturerCourseOption>[
        LecturerCourseOption(
          id: 'demo-course-1',
          code: 'SEN3141',
          title: 'Software Design and Modelling',
        ),
      ];
    }

    final String userId = _client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) {
      return const <LecturerCourseOption>[];
    }

    try {
      final List<dynamic> rows = await _client
          .from('courses')
          .select('id, course_code, title')
          .eq('lecturer_id', userId)
          .order('course_code');

      return rows
          .map(
            (dynamic row) => LecturerCourseOption(
              id: (row['id'] ?? '').toString(),
              code: (row['course_code'] ?? '').toString(),
              title: (row['title'] ?? '').toString(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <LecturerCourseOption>[];
    }
  }

  Future<CourseNote> uploadNote({
    required File file,
    required String title,
    required String courseId,
    required String courseCode,
    String description = '',
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
      return CourseNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId,
        courseCode: courseCode,
        title: title,
        description: description,
        fileName: fileName,
        filePath: file.path,
        fileSizeBytes: size,
        uploadedByName: 'Demo Lecturer',
        uploadedAt: DateTime.now(),
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

    await _uploadBinary(
      objectPath: objectPath,
      bytes: Uint8List.fromList(bytes),
      strategy: strategy,
      onProgress: onProgress,
    );

    final Map<String, dynamic> row = await _client
        .from('lecture_notes')
        .insert(<String, dynamic>{
          'course_id': courseId,
          'title': title,
          'description': description,
          'content_url': objectPath,
          'file_name': fileName,
          'file_size_bytes': size,
          'uploaded_by': uid,
        })
        .select(
          'id, course_id, title, description, content_url, file_name, file_size_bytes, created_at',
        )
        .single();

    return CourseNote(
      id: (row['id'] ?? '').toString(),
      courseId: (row['course_id'] ?? '').toString(),
      courseCode: courseCode,
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      fileName: (row['file_name'] ?? '').toString(),
      filePath: (row['content_url'] ?? '').toString(),
      fileSizeBytes: (row['file_size_bytes'] as num?)?.toInt() ?? 0,
      uploadedByName: 'You',
      uploadedAt:
          DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  Future<void> _uploadBinary({
    required String objectPath,
    required Uint8List bytes,
    required NoteUploadStrategy strategy,
    void Function(NoteUploadProgress progress)? onProgress,
  }) async {
    if (strategy == NoteUploadStrategy.singleShot) {
      await _client.storage.from('lecture-notes').uploadBinary(objectPath, bytes);
      onProgress?.call(
        const NoteUploadProgress(
          fraction: 1,
          message: 'Upload complete.',
        ),
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
        await _client.storage.from('lecture-notes').uploadBinary(objectPath, bytes);
        onProgress?.call(
          const NoteUploadProgress(
            fraction: 1,
            message: 'Upload complete.',
          ),
        );
        return;
      } catch (_) {
        attempt += 1;
        if (attempt >= _maxUploadAttempts) {
          rethrow;
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

  Future<List<CourseNote>> listNotes({
    required String courseId,
    required String courseCode,
    String search = '',
    String sort = 'newest',
  }) async {
    if (!SupabaseBootstrap.isConfigured) {
      return <CourseNote>[];
    }

    dynamic query = _client
        .from('lecture_notes')
        .select(
          'id, course_id, title, description, content_url, file_name, file_size_bytes, created_at, profiles:uploaded_by(full_name)',
        )
        .eq('course_id', courseId);

    if (search.trim().isNotEmpty) {
      query = query.ilike('title', '%${search.trim()}%');
    }

    if (sort == 'oldest') {
      query = query.order('created_at', ascending: true);
    } else if (sort == 'title') {
      query = query.order('title', ascending: true);
    } else {
      query = query.order('created_at', ascending: false);
    }

    final List<dynamic> rows = await query;

    return rows
        .map(
          (dynamic row) => CourseNote(
            id: (row['id'] ?? '').toString(),
            courseId: (row['course_id'] ?? '').toString(),
            courseCode: courseCode,
            title: (row['title'] ?? '').toString(),
            description: (row['description'] ?? '').toString(),
            fileName: (row['file_name'] ?? '').toString(),
            filePath: (row['content_url'] ?? '').toString(),
            fileSizeBytes: (row['file_size_bytes'] as num?)?.toInt() ?? 0,
            uploadedByName: (row['profiles']?['full_name'] ?? 'Unknown')
                .toString(),
            uploadedAt:
                DateTime.tryParse((row['created_at'] ?? '').toString()) ??
                DateTime.now(),
          ),
        )
        .toList(growable: false);
  }

  Future<String> createDownloadUrl(String objectPath) async {
    if (!SupabaseBootstrap.isConfigured) {
      return objectPath;
    }

    final String signedUrl = await _client.storage
        .from('lecture-notes')
        .createSignedUrl(objectPath, 60 * 30);
    return signedUrl;
  }

  Future<void> deleteNote(String noteId, String objectPath) async {
    if (!SupabaseBootstrap.isConfigured) {
      return;
    }

    await _client.from('lecture_notes').delete().eq('id', noteId);
    await _client.storage.from('lecture-notes').remove(<String>[objectPath]);
  }

  Future<void> updateNoteTitle(String noteId, String title) async {
    if (!SupabaseBootstrap.isConfigured) {
      return;
    }
    await _client
        .from('lecture_notes')
        .update(<String, dynamic>{'title': title})
        .eq('id', noteId);
  }
}
