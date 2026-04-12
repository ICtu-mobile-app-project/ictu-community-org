import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class TranscriptionApi {
  TranscriptionApi({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> transcribeAudio({
    required String lectureId,
    required String audioPath,
  }) async {
    FunctionResponse response;
    try {
      response = await _invokeTranscribe(
        lectureId: lectureId,
        audioPath: audioPath,
      );
    } on FunctionException catch (error) {
      if (!_isInvalidJwt(error)) {
        rethrow;
      }

      final AuthResponse refresh = await _client.auth.refreshSession();
      final String refreshedToken =
          refresh.session?.accessToken ?? _client.auth.currentSession?.accessToken ?? '';
      if (refreshedToken.isEmpty) {
        throw Exception(
          'Your session expired. Please log in again and retry transcription.',
        );
      }

      response = await _invokeTranscribe(
        lectureId: lectureId,
        audioPath: audioPath,
      );
    }

    final Map<String, dynamic> body = _asJsonMap(response.data);
    if (response.status >= 400 || body['success'] == false) {
      throw Exception(_extractError(body));
    }

    return body;
  }

  Future<FunctionResponse> _invokeTranscribe({
    required String lectureId,
    required String audioPath,
  }) {
    return _client.functions.invoke(
      'transcribe-audio',
      body: <String, dynamic>{'lectureId': lectureId, 'audioUrl': audioPath},
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
    final dynamic topLevelError = payload['error'] ?? payload['message'];
    if (topLevelError is String && topLevelError.trim().isNotEmpty) {
      return topLevelError;
    }

    final dynamic data = payload['data'];
    if (data is Map<String, dynamic>) {
      final dynamic nestedError = data['error'] ?? data['message'];
      if (nestedError is String && nestedError.trim().isNotEmpty) {
        return nestedError;
      }
    }

    return 'Transcription failed. Please try again.';
  }
}
