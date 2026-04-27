import 'package:flutter/foundation.dart';

@immutable
class CourseStudent {
  const CourseStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.enrolledAt,
    this.faculty,
    this.program,
    this.yearLevel,
  });

  final String id;
  final String fullName;
  final String email;
  final DateTime enrolledAt;
  final String? faculty;
  final String? program;
  final int? yearLevel;
}
