class LecturerCourseOption {
  const LecturerCourseOption({
    required this.id,
    required this.code,
    required this.title,
  });

  final String id;
  final String code;
  final String title;

  factory LecturerCourseOption.fromJson(Map<String, dynamic> json) {
    return LecturerCourseOption(
      id: (json['id'] ?? '').toString(),
      code: (json['course_code'] ?? json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_code': code,
      'title': title,
    };
  }
}
