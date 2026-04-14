import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/student_courses_repository.dart';
import '../models/student_course_overview.dart';

class CourseDetailsController extends ChangeNotifier {
  CourseDetailsController({StudentCoursesRepository? repository})
      : _repository = repository ?? StudentCoursesRepository();

  static const int pageSize = 20;

  final StudentCoursesRepository _repository;
  final List<StudentCourseOverview> _courses = <StudentCourseOverview>[];

  Timer? _debounce;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _isWorking = false;
  bool _hasMore = true;
  String? _error;
  String _query = '';
  int _nextPage = 0;
  StudentCourseOverview? _selectedCourse;
  bool _showOnlyMyCourses = false;

  List<StudentCourseOverview> get courses => List<StudentCourseOverview>.unmodifiable(_courses);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get isWorking => _isWorking;
  bool get hasMore => _hasMore;
  String? get error => _error;
  StudentCourseOverview? get selectedCourse => _selectedCourse;
  bool get showOnlyMyCourses => _showOnlyMyCourses;

  Future<void> toggleMyCourses(bool value) async {
    _showOnlyMyCourses = value;
    await _load(reset: true);
  }

  Future<void> loadInitial({String? initialCourseId}) => _load(reset: true, initialCourseId: initialCourseId);

  Future<void> refresh() => _load(reset: true);

  Future<void> loadMore() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) return;
    await _load(reset: false);
  }

  void onSearchChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load(reset: true);
    });
  }

  Future<void> selectCourse(StudentCourseOverview course) async {
    _selectedCourse = course;
    notifyListeners();

    if (course.isEnrolled) {
      await _loadCourseContent(course);
    }
  }

  Future<void> enroll(StudentCourseOverview course) async {
    _isWorking = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.enrollInCourse(course.id);
      
      // Update local state
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = _courses[index].copyWith(isEnrolled: true);
        if (_selectedCourse?.id == course.id) {
          _selectedCourse = _courses[index];
        }
      }
      
      await _loadCourseContent(_selectedCourse!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> _loadCourseContent(StudentCourseOverview course) async {
    _isWorking = true;
    notifyListeners();

    try {
      final data = await _repository.getCourseContent(course.id, course.code);
      
      final List<dynamic> notesJson = data['notes'] ?? [];
      final List<dynamic> alertsJson = data['alerts'] ?? [];

      final materials = notesJson.map((j) => CourseMaterialItem.fromNoteJson(j)).toList();
      final deadlines = alertsJson.map((j) => CourseDeadlineItem.fromAlertJson(j)).toList();

      final updatedCourse = course.copyWith(
        materials: materials,
        deadlines: deadlines,
      );

      // Update in list
      final index = _courses.indexWhere((c) => c.id == course.id);
      if (index != -1) {
        _courses[index] = updatedCourse;
      }
      
      if (_selectedCourse?.id == course.id) {
        _selectedCourse = updatedCourse;
      }
    } catch (e) {
      _error = 'Failed to load course content: $e';
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> _load({required bool reset, String? initialCourseId}) async {
    if (reset) {
      _isLoadingInitial = true;
      _error = null;
      _nextPage = 0;
      _hasMore = true;
      _courses.clear();
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final List<StudentCourseOverview> page;
      if (_showOnlyMyCourses) {
        page = await _repository.getMyCourses();
      } else {
        page = await _repository.getAvailableCourses(
          page: _nextPage,
          limit: pageSize,
          searchQuery: _query,
        );
      }

      if (reset) {
        _courses.clear();
      }
      _courses.addAll(page);

      _nextPage += 1;
      _hasMore = page.length == pageSize;

      // Handle initial course selection
      if (reset && _courses.isNotEmpty) {
        if (initialCourseId != null) {
          final found = _courses.firstWhere(
            (c) => c.id == initialCourseId,
            orElse: () => _courses.first,
          );
          await selectCourse(found);
        } else if (_selectedCourse == null) {
          await selectCourse(_courses.first);
        }
      } else if (_courses.isEmpty) {
        _selectedCourse = null;
      }
    } catch (e) {
      _error = 'Unable to load courses: $e';
    } finally {
      _isLoadingInitial = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
