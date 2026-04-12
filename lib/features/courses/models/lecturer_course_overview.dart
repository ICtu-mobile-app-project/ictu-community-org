class LecturerCourseOverview {
  const LecturerCourseOverview({
    required this.id,
    required this.code,
    required this.title,
    required this.students,
    required this.lectures,
    required this.lastActivity,
  });

  final String id;
  final String code;
  final String title;
  final int students;
  final int lectures;
  final DateTime lastActivity;

  factory LecturerCourseOverview.fromJson(Map<String, dynamic> json) {
    final DateTime? createdAt = DateTime.tryParse(
      (json['created_at'] ?? '').toString(),
    );

    return LecturerCourseOverview(
      id: (json['id'] ?? '').toString(),
      code: (json['course_code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      students: (json['students_count'] as num?)?.toInt() ?? 0,
      lectures: (json['lectures_count'] as num?)?.toInt() ?? 0,
      lastActivity: createdAt ?? DateTime.now(),
    );
  }
}

