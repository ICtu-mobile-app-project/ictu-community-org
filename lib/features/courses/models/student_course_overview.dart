class StudentCourseOverview {
  const StudentCourseOverview({
    required this.id,
    required this.code,
    required this.title,
    required this.lecturer,
    required this.progress,
    required this.materials,
    required this.deadlines,
  });

  final String id;
  final String code;
  final String title;
  final String lecturer;
  final double progress;
  final List<CourseMaterialItem> materials;
  final List<CourseDeadlineItem> deadlines;
}

class CourseMaterialItem {
  const CourseMaterialItem({required this.name, required this.size});

  final String name;
  final String size;
}

class CourseDeadlineItem {
  const CourseDeadlineItem({
    required this.title,
    required this.due,
    required this.colorHex,
  });

  final String title;
  final String due;
  final int colorHex;
}
