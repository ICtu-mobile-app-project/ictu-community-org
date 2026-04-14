import 'package:flutter/foundation.dart';

@immutable
class LecturerCourse {
  const LecturerCourse({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.semester,
    required this.lecturerId,
    required this.lecturerName,
    required this.studentCount,
    required this.lectureCount,
    required this.notesCount,
    required this.alertCount,
    required this.lastActivity,
    this.archived = false,
  });

  final String id;
  final String courseCode;
  final String title;
  final String description;
  final String semester;
  final String lecturerId;
  final String lecturerName;
  final int studentCount;
  final int lectureCount;
  final int notesCount;
  final int alertCount;
  final DateTime lastActivity;
  final bool archived;

  bool get hasContent => lectureCount > 0 || notesCount > 0 || alertCount > 0;

  LecturerCourse copyWith({
    String? title,
    String? description,
    String? semester,
    int? studentCount,
    int? lectureCount,
    int? notesCount,
    int? alertCount,
    DateTime? lastActivity,
    bool? archived,
  }) {
    return LecturerCourse(
      id: id,
      courseCode: courseCode,
      title: title ?? this.title,
      description: description ?? this.description,
      semester: semester ?? this.semester,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      studentCount: studentCount ?? this.studentCount,
      lectureCount: lectureCount ?? this.lectureCount,
      notesCount: notesCount ?? this.notesCount,
      alertCount: alertCount ?? this.alertCount,
      lastActivity: lastActivity ?? this.lastActivity,
      archived: archived ?? this.archived,
    );
  }
}
