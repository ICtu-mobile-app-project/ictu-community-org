import 'package:flutter/foundation.dart';
import 'package:ictu_community_org/features/courses/data/student_courses_repository.dart';
import 'package:ictu_community_org/features/courses/models/student_course_overview.dart';

class EnrolledCoursesController extends ChangeNotifier {
  EnrolledCoursesController({StudentCoursesRepository? repository})
      : _repository = repository ?? StudentCoursesRepository();

  final StudentCoursesRepository _repository;
  
  List<StudentCourseOverview> _enrolledCourses = [];
  bool _isLoading = false;
  String? _error;

  List<StudentCourseOverview> get enrolledCourses => List.unmodifiable(_enrolledCourses);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEnrolledCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _enrolledCourses = await _repository.getMyCourses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadEnrolledCourses();
}
