import '../../../core/constants/ictu_constants.dart';
import '../models/course_delegate.dart';
import '../models/course_page.dart';
import '../models/course_student.dart';
import '../models/lecturer_course.dart';
import 'lecturer_courses_repository.dart';

class InMemoryLecturerCoursesRepository implements LecturerCoursesRepository {
  InMemoryLecturerCoursesRepository._();

  static final InMemoryLecturerCoursesRepository instance =
      InMemoryLecturerCoursesRepository._();

  final List<LecturerCourse> _courses = <LecturerCourse>[
    LecturerCourse(
      id: 'course-1',
      courseCode: 'SEN3141',
      title: 'Software Design and Modelling',
      description:
          'Modeling techniques and software architecture fundamentals.',
      semester: 'Fall 2025',
      lecturerId: 'lecturer-1',
      lecturerName: 'Prof. Victor Mbarika',
      studentCount: 58,
      lectureCount: 14,
      notesCount: 8,
      alertCount: 3,
      lastActivity: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    LecturerCourse(
      id: 'course-2',
      courseCode: 'ICT2111',
      title: 'Technical Writing for Engineers',
      description: 'Professional communication in engineering contexts.',
      semester: 'Spring 2026',
      lecturerId: 'lecturer-1',
      lecturerName: 'Prof. Victor Mbarika',
      studentCount: 74,
      lectureCount: 10,
      notesCount: 5,
      alertCount: 4,
      lastActivity: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    LecturerCourse(
      id: 'course-3',
      courseCode: 'CSC4121',
      title: 'Artificial Intelligence',
      description: 'AI principles, search, reasoning, and agents.',
      semester: 'Summer 2025',
      lecturerId: 'lecturer-1',
      lecturerName: 'Prof. Victor Mbarika',
      studentCount: 43,
      lectureCount: 9,
      notesCount: 6,
      alertCount: 2,
      lastActivity: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<CourseStudent> _studentsDirectory = <CourseStudent>[
    CourseStudent(
      id: 'stu-1',
      fullName: 'Alice Ndam',
      email: 'alice.ndam@student.ictu-university.cm',
      enrolledAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    CourseStudent(
      id: 'stu-2',
      fullName: 'Brian Kome',
      email: 'brian.kome@student.ictu-university.cm',
      enrolledAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CourseStudent(
      id: 'stu-3',
      fullName: 'Carine Mbi',
      email: 'carine.mbi@student.ictu-university.cm',
      enrolledAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CourseStudent(
      id: 'stu-4',
      fullName: 'Daniel Eto',
      email: 'daniel.eto@student.ictu-university.cm',
      enrolledAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  final Map<String, List<String>> _courseStudentIds = <String, List<String>>{
    'course-1': <String>['stu-1', 'stu-2', 'stu-3'],
    'course-2': <String>['stu-2', 'stu-4'],
    'course-3': <String>['stu-1', 'stu-4'],
  };

  final Map<String, List<CourseDelegate>> _courseDelegates =
      <String, List<CourseDelegate>>{
        'course-1': <CourseDelegate>[
          const CourseDelegate(
            id: 'del-1',
            studentId: 'stu-1',
            studentName: 'Alice Ndam',
            studentEmail: 'alice.ndam@student.ictu-university.cm',
            canUploadNotes: true,
            canEditNotes: false,
            canDeleteNotes: false,
          ),
        ],
      };

  @override
  Future<CoursePage> getMyCourses({
    required String lecturerId,
    required int page,
    int limit = 20,
    String searchQuery = '',
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final String query = searchQuery.trim().toLowerCase();

    final List<LecturerCourse> scoped =
        _courses.where((LecturerCourse c) => c.lecturerId == lecturerId).where((
          LecturerCourse c,
        ) {
          if (query.isEmpty) {
            return true;
          }
          return c.courseCode.toLowerCase().contains(query) ||
              c.title.toLowerCase().contains(query);
        }).toList()..sort((LecturerCourse a, LecturerCourse b) {
          return b.lastActivity.compareTo(a.lastActivity);
        });

    final int from = page * limit;
    if (from >= scoped.length) {
      return const CoursePage(items: <LecturerCourse>[], hasMore: false);
    }
    final int to = (from + limit).clamp(0, scoped.length);

    return CoursePage(
      items: scoped.sublist(from, to),
      hasMore: to < scoped.length,
    );
  }

  @override
  Future<bool> courseCodeExists(String courseCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final String normalized = courseCode.trim().toUpperCase();
    return _courses.any((LecturerCourse c) => c.courseCode == normalized);
  }

  @override
  Future<bool> canTeachDepartment({
    required String lecturerId,
    required String courseCode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (courseCode.length < 3) {
      return false;
    }
    final String department = courseCode.substring(0, 3).toUpperCase();
    return ICTUConstants.supportedDepartments.contains(department);
  }

  @override
  Future<LecturerCourse> createCourse({
    required String lecturerId,
    required String lecturerName,
    required String courseCode,
    required String title,
    required String description,
    required String semester,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));

    final LecturerCourse created = LecturerCourse(
      id: 'course-${DateTime.now().millisecondsSinceEpoch}',
      courseCode: courseCode.trim().toUpperCase(),
      title: title.trim(),
      description: description.trim(),
      semester: semester,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      studentCount: 0,
      lectureCount: 0,
      notesCount: 0,
      alertCount: 0,
      lastActivity: DateTime.now(),
    );

    _courses.add(created);
    _courseStudentIds.putIfAbsent(created.id, () => <String>[]);
    return created;
  }

  @override
  Future<LecturerCourse> getCourseDetails(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _getCourse(courseId);
  }

  @override
  Future<LecturerCourse> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String semester,
    required bool archived,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final int index = _courses.indexWhere(
      (LecturerCourse c) => c.id == courseId,
    );
    if (index < 0) {
      throw StateError('Course not found');
    }

    final LecturerCourse updated = _courses[index].copyWith(
      title: title.trim(),
      description: description.trim(),
      semester: semester,
      archived: archived,
      lastActivity: DateTime.now(),
    );
    _courses[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCourse(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final LecturerCourse current = _getCourse(courseId);
    if (current.hasContent) {
      throw StateError('Cannot delete course with lectures, notes, or alerts.');
    }
    _courses.removeWhere((LecturerCourse c) => c.id == courseId);
    _courseStudentIds.remove(courseId);
    _courseDelegates.remove(courseId);
  }

  @override
  Future<List<CourseStudent>> getEnrolledStudents(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final List<String> ids = _courseStudentIds[courseId] ?? <String>[];
    return _studentsDirectory
        .where((CourseStudent s) => ids.contains(s.id))
        .toList()
      ..sort((CourseStudent a, CourseStudent b) {
        return b.enrolledAt.compareTo(a.enrolledAt);
      });
  }

  @override
  Future<List<CourseStudent>> searchStudentsByEmail(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return <CourseStudent>[];
    }
    return _studentsDirectory
        .where((CourseStudent s) => s.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<void> enrollStudents({
    required String courseId,
    required List<String> studentIds,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 170));
    final List<String> courseIds = _courseStudentIds.putIfAbsent(
      courseId,
      () => <String>[],
    );

    for (final String id in studentIds) {
      final bool exists = _studentsDirectory.any(
        (CourseStudent s) => s.id == id,
      );
      if (!exists) {
        throw StateError('Student does not exist: $id');
      }
      if (!courseIds.contains(id)) {
        courseIds.add(id);
      }
    }

    _touchCourse(courseId, studentCount: courseIds.length);
  }

  @override
  Future<void> removeStudent({
    required String courseId,
    required String studentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final List<String> courseIds = _courseStudentIds[courseId] ?? <String>[];
    courseIds.remove(studentId);

    _courseDelegates[courseId]?.removeWhere(
      (CourseDelegate d) => d.studentId == studentId,
    );

    _touchCourse(courseId, studentCount: courseIds.length);
  }

  @override
  Future<List<CourseDelegate>> getDelegates(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final List<CourseDelegate> delegates =
        _courseDelegates[courseId] ?? <CourseDelegate>[];
    return List<CourseDelegate>.from(delegates);
  }

  @override
  Future<CourseDelegate> assignDelegate({
    required String courseId,
    required String studentId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final CourseStudent student = _studentsDirectory.firstWhere(
      (CourseStudent s) => s.id == studentId,
      orElse: () => throw StateError('Student not found'),
    );

    final List<CourseDelegate> delegates = _courseDelegates.putIfAbsent(
      courseId,
      () => <CourseDelegate>[],
    );

    final int index = delegates.indexWhere(
      (CourseDelegate d) => d.studentId == studentId,
    );

    final CourseDelegate created = CourseDelegate(
      id: index >= 0
          ? delegates[index].id
          : 'delegate-${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.id,
      studentName: student.fullName,
      studentEmail: student.email,
      canUploadNotes: canUploadNotes,
      canEditNotes: canEditNotes,
      canDeleteNotes: canDeleteNotes,
    );

    if (index >= 0) {
      delegates[index] = created;
    } else {
      delegates.add(created);
    }

    _touchCourse(courseId);
    return created;
  }

  @override
  Future<CourseDelegate> updateDelegatePermissions({
    required String courseId,
    required String delegateId,
    required bool canUploadNotes,
    required bool canEditNotes,
    required bool canDeleteNotes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final List<CourseDelegate> delegates =
        _courseDelegates[courseId] ?? <CourseDelegate>[];
    final int index = delegates.indexWhere(
      (CourseDelegate d) => d.id == delegateId,
    );
    if (index < 0) {
      throw StateError('Delegate not found');
    }

    final CourseDelegate updated = delegates[index].copyWith(
      canUploadNotes: canUploadNotes,
      canEditNotes: canEditNotes,
      canDeleteNotes: canDeleteNotes,
    );

    delegates[index] = updated;
    _touchCourse(courseId);
    return updated;
  }

  @override
  Future<void> removeDelegate({
    required String courseId,
    required String delegateId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 130));
    _courseDelegates[courseId]?.removeWhere(
      (CourseDelegate d) => d.id == delegateId,
    );
    _touchCourse(courseId);
  }

  LecturerCourse _getCourse(String courseId) {
    return _courses.firstWhere(
      (LecturerCourse c) => c.id == courseId,
      orElse: () => throw StateError('Course not found'),
    );
  }

  void _touchCourse(String courseId, {int? studentCount}) {
    final int index = _courses.indexWhere(
      (LecturerCourse c) => c.id == courseId,
    );
    if (index < 0) {
      return;
    }

    _courses[index] = _courses[index].copyWith(
      lastActivity: DateTime.now(),
      studentCount: studentCount,
    );
  }
}
