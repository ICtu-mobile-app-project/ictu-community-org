class LecturerCourseOverview {
  const LecturerCourseOverview({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.semester,
    required this.students,
    required this.notes,
    required this.alerts,
    required this.lastActivity,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String semester;
  final int students;
  final int notes;
  final int alerts;
  final DateTime lastActivity;

  factory LecturerCourseOverview.fromJson(Map<String, dynamic> json) {
    final DateTime? createdAt = DateTime.tryParse(
      (json['created_at'] ?? '').toString(),
    );

    return LecturerCourseOverview(
      id: (json['id'] ?? '').toString(),
      code: (json['course_code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      semester: (json['semester'] ?? '').toString(),
      students: (json['students_count'] as num?)?.toInt() ?? 0,
      notes: (json['notes_count'] as num?)?.toInt() ?? 0,
      alerts: (json['alerts_count'] as num?)?.toInt() ?? 0,
      lastActivity: createdAt ?? DateTime.now(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': code,
      'title': title,
      'description': description,
      'semester': semester,
      'students_count': students,
      'notes_count': notes,
      'alerts_count': alerts,
      'created_at': lastActivity.toIso8601String(),
    };
  }

  LecturerCourseOverview copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? semester,
    int? students,
    int? notes,
    int? alerts,
    DateTime? lastActivity,
  }) {
    return LecturerCourseOverview(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      semester: semester ?? this.semester,
      students: students ?? this.students,
      notes: notes ?? this.notes,
      alerts: alerts ?? this.alerts,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

