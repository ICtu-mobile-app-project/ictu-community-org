import 'package:flutter/foundation.dart';

@immutable
class CourseNote {
  const CourseNote({
    required this.id,
    required this.courseId,
    this.courseCode = '',
    required this.title,
    required this.description,
    required this.contentUrl,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String courseCode;
  final String title;
  final String description;
  final String contentUrl;
  final String fileName;
  final int fileSizeBytes;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime createdAt;

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  String get sizeLabel {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    }
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get fileSizeLabel => sizeLabel;

  DateTime get uploadedAt => createdAt;

  String get filePath => contentUrl;

  factory CourseNote.fromJson(Map<String, dynamic> json) {
    return CourseNote(
      id: (json['id'] ?? json['noteId'] ?? '').toString(),
      courseId: (json['course_id'] ?? json['courseId'] ?? '').toString(),
      courseCode: (json['course_code'] ?? json['courseCode'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      contentUrl: (json['content_url'] ?? json['contentUrl'] ?? '').toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? '').toString(),
      fileSizeBytes: ((json['file_size'] ?? json['fileSizeBytes'] ?? 0) as num).toInt(),
      uploadedBy: (json['uploaded_by'] ?? json['uploadedBy'] ?? '').toString(),
      uploadedByName: (json['uploader_name'] ?? json['uploadedByName'] ?? 'Unknown').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'course_code': courseCode,
      'title': title,
      'description': description,
      'content_url': contentUrl,
      'file_name': fileName,
      'file_size': fileSizeBytes,
      'uploaded_by': uploadedBy,
      'uploader_name': uploadedByName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
