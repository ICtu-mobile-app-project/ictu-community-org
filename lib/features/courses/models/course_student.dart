import 'package:flutter/foundation.dart';

@immutable
class CourseStudent {
  const CourseStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.enrolledAt,
  });

  final String id;
  final String fullName;
  final String email;
  final DateTime enrolledAt;
}
