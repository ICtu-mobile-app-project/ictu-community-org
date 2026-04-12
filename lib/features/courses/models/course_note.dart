import 'package:flutter/foundation.dart';

@immutable
class CourseNote {
  const CourseNote({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.uploadedByName,
    required this.uploadedAt,
  });

  final String id;
  final String courseId;
  final String courseCode;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String uploadedByName;
  final DateTime uploadedAt;

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  String get fileSizeLabel {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    }
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

@immutable
class LecturerCourseOption {
  const LecturerCourseOption({
    required this.id,
    required this.code,
    required this.title,
  });

  final String id;
  final String code;
  final String title;
}
