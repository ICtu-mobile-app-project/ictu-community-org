import 'transcription_api.dart';

class TranscriptionRepository {
  TranscriptionRepository({TranscriptionApi? api})
    : _api = api ?? TranscriptionApi();

  final TranscriptionApi _api;

  Future<Map<String, dynamic>> transcribeAudio({
    required String lectureId,
    required String audioPath,
  }) {
    return _api.transcribeAudio(lectureId: lectureId, audioPath: audioPath);
  }
}
