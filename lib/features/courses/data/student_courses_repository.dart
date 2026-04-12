import 'dart:math';

import '../models/student_course_overview.dart';

class StudentCoursesRepository {
  static const Duration _cacheExpiry = Duration(hours: 1);
  static final Map<String, _CachedCoursesPage> _cache =
      <String, _CachedCoursesPage>{};

  Future<List<StudentCourseOverview>> getCourses({
    required int page,
    int limit = 20,
    String? searchQuery,
    bool forceRefresh = false,
  }) async {
    final String query = searchQuery?.trim().toLowerCase() ?? '';
    final String key = '$page:$limit:$query';

    final _CachedCoursesPage? cached = _cache[key];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      return cached.data;
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));

    final List<StudentCourseOverview> source = _sampleCourses
        .where((StudentCourseOverview item) {
          if (query.isEmpty) {
            return true;
          }
          return item.code.toLowerCase().contains(query) ||
              item.title.toLowerCase().contains(query);
        })
        .toList(growable: false);

    final int from = page * limit;
    if (from >= source.length) {
      _cache[key] = _CachedCoursesPage(data: const <StudentCourseOverview>[]);
      return const <StudentCourseOverview>[];
    }

    final int to = min(from + limit, source.length);
    final List<StudentCourseOverview> paged = source.sublist(from, to);
    _cache[key] = _CachedCoursesPage(data: paged);
    return paged;
  }
}

class _CachedCoursesPage {
  _CachedCoursesPage({required this.data}) : timestamp = DateTime.now();

  final DateTime timestamp;
  final List<StudentCourseOverview> data;

  bool get isExpired =>
      DateTime.now().difference(timestamp) >
      StudentCoursesRepository._cacheExpiry;
}

const List<StudentCourseOverview> _sampleCourses = <StudentCourseOverview>[
  StudentCourseOverview(
    id: 'course-sen3141',
    code: 'SEN3141',
    title: 'Software Design and Modelling',
    lecturer: 'Dr. Ngwa Mercy',
    progress: 0.72,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(
        name: 'Week 7 - UML Design Patterns.pdf',
        size: '3.1 MB',
      ),
      CourseMaterialItem(
        name: 'SEN3141 Group Project Brief.pdf',
        size: '1.8 MB',
      ),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Midterm Exam - SEN3141',
        due: 'Apr 18, 10:00 AM',
        colorHex: 0xFFF59E0B,
      ),
      CourseDeadlineItem(
        title: 'Team Modelling Submission',
        due: 'Apr 14, 11:59 PM',
        colorHex: 0xFFFB7185,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-ict3111',
    code: 'ICT3111',
    title: 'Relational Databases and Web Integration',
    lecturer: 'Dr. Sarah Johnson',
    progress: 0.58,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(
        name: 'DBMS Query Optimization Slides.pptx',
        size: '7.8 MB',
      ),
      CourseMaterialItem(
        name: 'Normalization Revision Notes.pdf',
        size: '2.4 MB',
      ),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Assignment 3 - ICT3111',
        due: 'Apr 22, 11:59 PM',
        colorHex: 0xFFFB7185,
      ),
      CourseDeadlineItem(
        title: 'SQL Lab Report',
        due: 'Apr 16, 04:00 PM',
        colorHex: 0xFF22C55E,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-csc1122',
    code: 'CSC1122',
    title: 'Algorithms and Data Structures I',
    lecturer: 'Prof. Etoundi Alain',
    progress: 0.66,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Complexity Analysis Sheet.pdf', size: '1.2 MB'),
      CourseMaterialItem(name: 'Recursion Practice Set.pdf', size: '920 KB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Quiz 5 - Sorting',
        due: 'Apr 19, 08:00 AM',
        colorHex: 0xFFF59E0B,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-csc1222',
    code: 'CSC1222',
    title: 'Algorithms and Data Structures II',
    lecturer: 'Dr. Molua Diane',
    progress: 0.41,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Graphs and Trees Handout.pdf', size: '2.0 MB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Project Checkpoint',
        due: 'Apr 25, 05:00 PM',
        colorHex: 0xFF22C55E,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-sen2142',
    code: 'SEN2142',
    title: 'Java Programming I',
    lecturer: 'Mr. Tabi Collins',
    progress: 0.79,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'OOP Basics Slides.pdf', size: '2.6 MB'),
      CourseMaterialItem(name: 'Java Lab Guide 4.pdf', size: '1.1 MB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Lab 4 Submission',
        due: 'Apr 17, 11:59 PM',
        colorHex: 0xFFFB7185,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-sen2242',
    code: 'SEN2242',
    title: 'Java Programming II',
    lecturer: 'Mrs. Nchinda Grace',
    progress: 0.52,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Spring Intro Practical.pdf', size: '1.9 MB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Mini Project Demo',
        due: 'Apr 30, 02:00 PM',
        colorHex: 0xFFF59E0B,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-isn3131',
    code: 'ISN3131',
    title: 'CCNA 1',
    lecturer: 'Eng. Nana Peter',
    progress: 0.63,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Networking Fundamentals.pdf', size: '5.2 MB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Packet Tracer Lab',
        due: 'Apr 20, 06:00 PM',
        colorHex: 0xFF22C55E,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-csc4121',
    code: 'CSC4121',
    title: 'Artificial Intelligence',
    lecturer: 'Dr. Koki Benjamin',
    progress: 0.47,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Search Algorithms Notes.pdf', size: '2.7 MB'),
      CourseMaterialItem(name: 'AI Assignment Template.docx', size: '600 KB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'A* Implementation Task',
        due: 'Apr 27, 11:59 PM',
        colorHex: 0xFFFB7185,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-cys4151',
    code: 'CYS4151',
    title: 'Ethical Hacking',
    lecturer: 'Mr. Ewane Franklin',
    progress: 0.36,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(name: 'Pen Testing Checklist.pdf', size: '1.4 MB'),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Lab Safety Quiz',
        due: 'Apr 15, 09:30 AM',
        colorHex: 0xFFF59E0B,
      ),
    ],
  ),
  StudentCourseOverview(
    id: 'course-sen3142',
    code: 'SEN3142',
    title: 'Introduction to Mobile Application Development',
    lecturer: 'Dr. Fobang Linda',
    progress: 0.68,
    materials: <CourseMaterialItem>[
      CourseMaterialItem(
        name: 'Flutter Widgets Cheat Sheet.pdf',
        size: '1.5 MB',
      ),
    ],
    deadlines: <CourseDeadlineItem>[
      CourseDeadlineItem(
        title: 'Prototype Review',
        due: 'Apr 24, 03:00 PM',
        colorHex: 0xFF22C55E,
      ),
    ],
  ),
];
