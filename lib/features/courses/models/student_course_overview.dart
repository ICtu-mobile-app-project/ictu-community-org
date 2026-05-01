import 'package:flutter/foundation.dart';

@immutable
class StudentCourseOverview {
  const StudentCourseOverview({
    required this.id,
    required this.code,
    required this.title,
    required this.lecturer,
    required this.description,
    this.progress = 0.0,
    this.isEnrolled = false,
    this.notesCount = 0,
    this.alertsCount = 0,
    this.materials = const <CourseMaterialItem>[],
    this.deadlines = const <CourseDeadlineItem>[],
  });

  final String id;
  final String code;
  final String title;
  final String lecturer;
  final String description;
  final double progress;
  final bool isEnrolled;
  final int notesCount;
  final int alertsCount;
  final List<CourseMaterialItem> materials;
  final List<CourseDeadlineItem> deadlines;

  factory StudentCourseOverview.fromJson(Map<String, dynamic> json) {
    return StudentCourseOverview(
      id: (json['id'] ?? '').toString(),
      code: (json['course_code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      lecturer: (json['lecturer_name'] ?? 'Unknown Lecturer').toString(),
      description: (json['description'] ?? '').toString(),
      isEnrolled: json['is_enrolled'] == true || json['is_enrolled'] == 'true',
      progress: ((json['progress'] ?? 0.0) as num).toDouble(),
      notesCount: ((json['notes_count'] ?? 0) as num).toInt(),
      alertsCount: ((json['alerts_count'] ?? 0) as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': code,
      'title': title,
      'lecturer_name': lecturer,
      'description': description,
      'is_enrolled': isEnrolled,
      'progress': progress,
      'notes_count': notesCount,
      'alerts_count': alertsCount,
    };
  }

  StudentCourseOverview copyWith({
    List<CourseMaterialItem>? materials,
    List<CourseDeadlineItem>? deadlines,
    bool? isEnrolled,
  }) {
    return StudentCourseOverview(
      id: id,
      code: code,
      title: title,
      lecturer: lecturer,
      description: description,
      progress: progress,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      materials: materials ?? this.materials,
      deadlines: deadlines ?? this.deadlines,
    );
  }
}

@immutable
class CourseMaterialItem {
  const CourseMaterialItem({
    required this.id,
    required this.name,
    required this.size,
    required this.path,
  });

  final String id;
  final String name;
  final String size;
  final String path;

  factory CourseMaterialItem.fromNoteJson(Map<String, dynamic> json) {
    return CourseMaterialItem(
      id: (json['id'] ?? '').toString(),
      name: (json['title'] ?? 'Unnamed Note').toString(),
      size: '---', // Size is not stored in DB currently, we show placeholder
      path: (json['content_url'] ?? '').toString(),
    );
  }
}

@immutable
class CourseDeadlineItem {
  const CourseDeadlineItem({
    required this.id,
    required this.title,
    required this.due,
    required this.type,
    required this.colorHex,
  });

  final String id;
  final String title;
  final String due;
  final String type;
  final int colorHex;

  factory CourseDeadlineItem.fromAlertJson(Map<String, dynamic> json) {
    final String type = (json['type'] ?? 'alert').toString().toLowerCase();
    int color = 0xFFF59E0B; // Default Orange
    
    if (type.contains('exam')) {
      color = 0xFFEF4444; // Red
    } else if (type.contains('assignment') || type.contains('ca')) {
      color = 0xFF3B82F6; // Blue
    }

    return CourseDeadlineItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      due: (json['deadline'] ?? '').toString(),
      type: type,
      colorHex: color,
    );
  }
}
