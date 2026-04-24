import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';

class CoursePage {
  const CoursePage({required this.items, required this.hasMore});

  final List<LecturerCourse> items;
  final bool hasMore;
}
