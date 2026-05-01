import 'package:ictu_community_org/features/courses/models/lecturer_course.dart';
import 'package:ictu_community_org/features/courses/models/lecturer_course_overview.dart';
import 'package:ictu_community_org/features/courses/data/lecturer_courses_repository.dart';

class InMemoryLecturerCoursesRepository implements LecturerCoursesRepository {
  InMemoryLecturerCoursesRepository._();

  static final InMemoryLecturerCoursesRepository instance =
      InMemoryLecturerCoursesRepository._();

  final List<LecturerCourseOverview> _courses = <LecturerCourseOverview>[
    LecturerCourseOverview(
      id: 'course-1',
      code: 'SEN3141',
      title: 'Software Design and Modelling',
      description:
          'Modeling techniques and software architecture fundamentals.',
      semester: 'Fall 2025',
      students: 58,
      notes: 8,
      alerts: 3,
      lastActivity: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    LecturerCourseOverview(
      id: 'course-2',
      code: 'ICT2111',
      title: 'Technical Writing for Engineers',
      description: 'Professional communication in engineering contexts.',
      semester: 'Spring 2026',
      students: 74,
      notes: 5,
      alerts: 4,
      lastActivity: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    LecturerCourseOverview(
      id: 'course-3',
      code: 'CSC4121',
      title: 'Artificial Intelligence',
      description: 'AI principles, search, reasoning, and agents.',
      semester: 'Summer 2025',
      students: 43,
      notes: 6,
      alerts: 2,
      lastActivity: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<LecturerCourseOverview>> getCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final String query = searchQuery?.trim().toLowerCase() ?? '';

    final List<LecturerCourseOverview> scoped = _courses.where((LecturerCourseOverview c) {
      if (query.isEmpty) {
        return true;
      }
      return c.code.toLowerCase().contains(query) ||
          c.title.toLowerCase().contains(query);
    }).toList()..sort((LecturerCourseOverview a, LecturerCourseOverview b) {
      return b.lastActivity.compareTo(a.lastActivity);
    });

    final int from = page * limit;
    if (from >= scoped.length) {
      return <LecturerCourseOverview>[];
    }
    final int to = (from + limit).clamp(0, scoped.length);

    return scoped.sublist(from, to);
  }

  @override
  Future<LecturerCoursesResult> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String? searchQuery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final String query = searchQuery?.trim().toLowerCase() ?? '';
    final List<LecturerCourseOverview> filtered = _courses.where((c) {
      if (query.isEmpty) return true;
      return c.code.toLowerCase().contains(query) ||
          c.title.toLowerCase().contains(query);
    }).toList();

    final int from = page * limit;
    if (from >= filtered.length) {
      return const LecturerCoursesResult(items: [], hasMore: false);
    }

    final int to = (from + limit).clamp(0, filtered.length);
    final List<LecturerCourse> items = filtered
        .sublist(from, to)
        .map(
          (c) => LecturerCourse(
            id: c.id,
            courseCode: c.code,
            title: c.title,
            description: c.description,
            semester: c.semester,
            lecturerId: lecturerId,
            lecturerName: 'Prof. Victor Mbarika',
            studentCount: c.students,
            lectureCount: 0,
            notesCount: c.notes,
            alertCount: c.alerts,
            lastActivity: c.lastActivity,
          ),
        )
        .toList();

    return LecturerCoursesResult(items: items, hasMore: to < filtered.length);
  }

  @override
  Future<void> createCourse({
    required String lecturerId,
    required String courseCode,
    required String title,
    required String semester,
    String description = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));

    final LecturerCourseOverview created = LecturerCourseOverview(
      id: 'course-${DateTime.now().millisecondsSinceEpoch}',
      code: courseCode.trim().toUpperCase(),
      title: title.trim(),
      description: description.trim(),
      semester: semester,
      students: 0,
      notes: 0,
      alerts: 0,
      lastActivity: DateTime.now(),
    );

    _courses.add(created);
  }

  @override
  Future<int> getMyCoursesCount() async {
    return _courses.length;
  }
}
