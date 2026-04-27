import 'package:flutter/foundation.dart';

@immutable
class CourseDelegate {
  const CourseDelegate({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
}
