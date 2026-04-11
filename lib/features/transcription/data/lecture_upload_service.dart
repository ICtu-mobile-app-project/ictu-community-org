import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class LectureUploadService {
  LectureUploadService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const String _bucket = 'lecture-audio';
  final SupabaseClient _client;

  static String normalizeLocalPath(String value) {
    final String input = value.trim();
    if (input.startsWith('file://')) {
      try {
        return Uri.parse(input).toFilePath();
      } catch (_) {
        return input.replaceFirst('file://', '');
      }
    }
    return input;
  }

  Future<String> uploadAudioFile({required File file}) async {
    return uploadAudioPath(path: file.path, fallbackFileName: p.basename(file.path));
  }

  Future<String> uploadAudioPath({
    required String path,
    String? fallbackFileName,
  }) async {
    final String uid = _requireUserId();
    final String normalizedPath = normalizeLocalPath(path);
    if (normalizedPath.isEmpty) {
      throw Exception('Recorded file path is empty. Please record again.');
    }

    final File file = File(normalizedPath);
    final Uint8List fileBytes = await _readFileBytesWithRetry(file);
    if (fileBytes.isEmpty) {
      throw Exception('Recorded audio is empty. Please record again.');
    }

    final String fileName = _safeUploadName(
      p.basename(normalizedPath),
      fallbackFileName: fallbackFileName,
    );
    final String objectPath =
        'lectures/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from(_bucket).uploadBinary(objectPath, fileBytes);
    return objectPath;
  }

  Future<String> uploadAudioBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final String uid = _requireUserId();
    final String safeName = fileName.trim().isEmpty
        ? 'recording.m4a'
        : fileName.trim();
    final String objectPath =
        'lectures/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(_bucket).uploadBinary(objectPath, bytes);

    return objectPath;
  }

  Future<String> createLectureRow({
    required String audioPath,
    String? title,
    String? courseCode,
  }) async {
    final String uid = _requireUserId();
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': uid,
      'audio_url': audioPath,
      'title': title?.trim(),
      'course_code': _normalizedCourseCode(courseCode),
      'status': 'processing',
    };

    try {
      final Map<String, dynamic> inserted = await _client
          .from('lectures')
          .insert(payload)
          .select('id')
          .single();
      return inserted['id'] as String;
    } on PostgrestException catch (error) {
      final bool missingUserIdColumn = error.code == 'PGRST204' &&
          error.message.toLowerCase().contains("'user_id' column");
      if (!missingUserIdColumn) {
        rethrow;
      }

      final Map<String, dynamic> fallback = Map<String, dynamic>.from(payload)
        ..remove('user_id');
      final Map<String, dynamic> inserted = await _client
          .from('lectures')
          .insert(fallback)
          .select('id')
          .single();
      return inserted['id'] as String;
    }
  }

  String _requireUserId() {
    final String? uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      throw StateError('You must be logged in to upload lecture audio.');
    }
    return uid;
  }

  String _safeUploadName(String value, {String? fallbackFileName}) {
    final String trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    final String fallback = fallbackFileName?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }
    return 'recording.m4a';
  }

  Future<Uint8List> _readFileBytesWithRetry(File file) async {
    for (int i = 0; i < 6; i += 1) {
      if (await file.exists()) {
        final Uint8List bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          return bytes;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }

    throw Exception(
      'Could not access recorded file on this device. Please record again or use Pick Audio File.',
    );
  }

  String _normalizedCourseCode(String? courseCode) {
    final String normalized = courseCode?.trim().toUpperCase() ?? '';
    return normalized.isEmpty ? 'UNKNOWN' : normalized;
  }
}
