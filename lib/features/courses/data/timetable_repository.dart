import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/schedule_item.dart';

class TimetableRepository {
  final SupabaseClient _supabase;

  TimetableRepository(this._supabase);

  Future<List<ScheduleItem>> getStudentTimetable() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // 1. Get user's enrolled course codes
      final enrollmentResponse = await _supabase
          .from('course_enrollments')
          .select('course_code')
          .eq('student_id', user.id);
      
      final enrolledCodes = (enrollmentResponse as List)
          .map((e) => e['course_code'] as String)
          .toSet();

      // 2. Fetch ALL schedules
      final scheduleResponse = await _supabase
          .from('schedules')
          .select()
          .order('start_time');

      final List<dynamic> data = scheduleResponse as List;
      
      return data.map((json) {
        final String code = json['course_code'] as String;
        return ScheduleItem.fromJson(json, isEnrolled: enrolledCodes.contains(code));
      }).toList();

    } catch (e) {
      return [];
    }
  }

  Future<List<ScheduleItem>> getAllSchedules() async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .order('day_of_week')
          .order('start_time');

      return (response as List)
          .map((json) => ScheduleItem.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ScheduleItem>> getLecturerTimetable(String lecturerName) async {
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .ilike('lecturer', '%$lecturerName%')
          .order('start_time');

      return (response as List)
          .map((json) => ScheduleItem.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadSchedules(List<Map<String, dynamic>> schedules) async {
    try {
      // Bulk insert
      await _supabase.from('schedules').insert(schedules);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearTimetable() async {
    try {
      await _supabase.from('schedules').delete().neq('id', '00000000-0000-0000-0000-000000000000');
    } catch (e) {
      rethrow;
    }
  }
}
