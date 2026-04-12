enum NoteUploadStrategy {
  singleShot,
  chunkedRetry,
}

class NoteUploadProgress {
  const NoteUploadProgress({
    required this.fraction,
    required this.message,
  });

  final double fraction;
  final String message;
}

