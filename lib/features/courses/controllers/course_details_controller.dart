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
  bool _hasMore = true;
  String? _error;
  String _query = '';
  int _nextPage = 0;
  StudentCourseOverview? _selectedCourse;

  List<StudentCourseOverview> get courses =>
      List<StudentCourseOverview>.unmodifiable(_courses);
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  StudentCourseOverview? get selectedCourse => _selectedCourse;

  Future<void> loadInitial() => _load(reset: true);

  Future<void> refresh() => _load(reset: true, forceRefresh: true);

  Future<void> loadMore() async {
    if (_isLoadingInitial || _isLoadingMore || !_hasMore) {
      return;
    }
    await _load(reset: false);
  }

  void onSearchChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load(reset: true);
    });
  }

  void selectCourse(StudentCourseOverview course) {
    _selectedCourse = course;
    notifyListeners();
  }

  Future<void> _load({required bool reset, bool forceRefresh = false}) async {
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
      final List<StudentCourseOverview> page = await _repository.getCourses(
        page: _nextPage,
        limit: pageSize,
        searchQuery: _query,
        forceRefresh: forceRefresh,
      );

      if (reset) {
        _courses
          ..clear()
          ..addAll(page);
      } else {
        _courses.addAll(page);
      }

      _nextPage += 1;
      _hasMore = page.length == pageSize;

      if (_courses.isEmpty) {
        _selectedCourse = null;
      } else {
        final String? selectedId = _selectedCourse?.id;
        _selectedCourse = _courses.firstWhere(
          (StudentCourseOverview item) => item.id == selectedId,
          orElse: () => _courses.first,
        );
      }
    } catch (_) {
      _error = 'Unable to load courses right now. Please try again.';
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
