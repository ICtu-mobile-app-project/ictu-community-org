import 'package:flutter/foundation.dart';
import '../../auth/models/user_role.dart';
import '../models/schedule_item.dart';
import '../data/timetable_repository.dart';

class TimetableController extends ChangeNotifier {
  final TimetableRepository _repository;

  TimetableController(this._repository);

  List<ScheduleItem> _allSchedules = [];
  bool _isLoading = false;
  String? _error;

  List<ScheduleItem> get allSchedules => _allSchedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTimetable({
    UserRole role = UserRole.student,
    String? lecturerName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (role == UserRole.admin) {
        _allSchedules = await _repository.getAllSchedules();
      } else if (role == UserRole.lecturer && lecturerName != null) {
        _allSchedules = await _repository.getLecturerTimetable(lecturerName);
      } else {
        _allSchedules = await _repository.getStudentTimetable();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ScheduleItem> getSchedulesForDay(String day) {
    return _allSchedules
        .where((s) => s.dayOfWeek.toUpperCase() == day.toUpperCase())
        .toList();
  }
}
