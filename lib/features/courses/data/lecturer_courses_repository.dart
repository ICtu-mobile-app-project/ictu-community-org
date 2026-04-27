import 'package:ictu_community_org/features/courses/models/course_delegate.dart';
import 'package:ictu_community_org/features/courses/models/course_student.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';

class LecturerCoursesResult {
  const LecturerCoursesResult({
    required this.items,
    required this.hasMore,
  });

  final List<LecturerCourse> items;
  final bool hasMore;
}

abstract class LecturerCoursesRepository {
  Future<List<LecturerCourseOverview>> getCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
    bool forceRefresh = false,
  });

  Future<LecturerCoursesResult> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String? searchQuery,
  });

  Future<void> createCourse({
    required String lecturerId,
    required String courseCode,
    required String title,
    required String semester,
    String description = '',
  });

  Future<int> getMyCoursesCount();

  Future<List<CourseStudent>> getEnrolledStudents(String courseId);

  Future<List<CourseDelegate>> getDelegates(String courseId);
}
