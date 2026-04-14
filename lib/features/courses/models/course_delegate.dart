import 'package:flutter/foundation.dart';

@immutable
class CourseDelegate {
  const CourseDelegate({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.canUploadNotes,
    required this.canEditNotes,
    required this.canDeleteNotes,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final bool canUploadNotes;
  final bool canEditNotes;
  final bool canDeleteNotes;

  CourseDelegate copyWith({
    bool? canUploadNotes,
    bool? canEditNotes,
    bool? canDeleteNotes,
  }) {
    return CourseDelegate(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentEmail: studentEmail,
      canUploadNotes: canUploadNotes ?? this.canUploadNotes,
      canEditNotes: canEditNotes ?? this.canEditNotes,
      canDeleteNotes: canDeleteNotes ?? this.canDeleteNotes,
    );
  }
}
