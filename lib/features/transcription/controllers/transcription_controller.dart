import 'package:flutter/foundation.dart';

import '../data/transcription_repository.dart';

class TranscriptionController {
  TranscriptionController({TranscriptionRepository? repository})
    : _repository = repository ?? TranscriptionRepository();

  final TranscriptionRepository _repository;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<Map<String, dynamic>?> lastResult =
      ValueNotifier<Map<String, dynamic>?>(null);

  Future<void> transcribeAudio({
    required String lectureId,
    required String audioPath,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      lastResult.value = await _repository.transcribeAudio(
        lectureId: lectureId,
        audioPath: audioPath,
      );
    } catch (error) {
      errorMessage.value = error
          .toString()
          .replaceFirst('Exception: ', '')
          .trim();
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    lastResult.dispose();
  }
}
