import 'package:flutter/foundation.dart';

@immutable
class CourseNote {
  const CourseNote({
    required this.id,
    required this.courseId,
<<<<<<< Updated upstream
    required this.courseCode,
    required this.title,
    required this.description,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.uploadedByName,
    required this.uploadedAt,
=======
    required this.title,
    required this.description,
    required this.contentUrl,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
>>>>>>> Stashed changes
  });

  final String id;
  final String courseId;
<<<<<<< Updated upstream
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
=======
  final String title;
  final String description;
  final String contentUrl;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  String get sizeLabel {
>>>>>>> Stashed changes
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    }
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
<<<<<<< Updated upstream

  factory CourseNote.fromJson(Map<String, dynamic> json) {
    return CourseNote(
      id: (json['id'] ?? '').toString(),
      courseId: (json['course_id'] ?? '').toString(),
      courseCode: (json['course_code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fileName: (json['file_name'] ?? '').toString(),
      filePath: (json['content_url'] ?? '').toString(),
      fileSizeBytes: (json['file_size'] ?? 0).toInt(),
      uploadedByName: (json['uploader_name'] ?? 'Unknown').toString(),
      uploadedAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_code': courseCode,
      'title': title,
      'description': description,
      'file_name': fileName,
      'content_url': filePath,
      'file_size': fileSizeBytes,
      'uploader_name': uploadedByName,
      'created_at': uploadedAt.toIso8601String(),
    };
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
=======
>>>>>>> Stashed changes
}
