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

  Future<List<ScheduleItem>> getLecturerTimetable(String? lecturerName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // 1. Fetch ALL schedules first (Resilience: always show the master timetable)
      final scheduleResponse = await _supabase
          .from('schedules')
          .select()
          .order('start_time');
      final List<dynamic> scheduleData = scheduleResponse as List;

      // 2. Try to get courses taught by this lecturer for highlighting
      Set<String> teachingCodes = {};
      try {
        final coursesResponse = await _supabase
            .from('courses')
            .select('course_code')
            .eq('lecturer_id', user.id);
        
        teachingCodes = (coursesResponse as List)
            .map((e) => e['course_code'] as String)
            .toSet();
      } catch (e) {
        // Silently fail highlighting logic, but keep going with the schedule
        print('Error fetching teaching courses: $e');
      }

      // 3. Map schedules and mark "isMine"
      return scheduleData.map((json) {
        final String code = json['course_code'] as String;
        final String? schedLecturer = json['lecturer'] as String?;
        
        bool isMine = teachingCodes.contains(code);
        
        // Fallback to name matching if not found by ID mapping
        if (!isMine && lecturerName != null && schedLecturer != null) {
          final name = lecturerName.toLowerCase();
          final sched = schedLecturer.toLowerCase();
          
          // Flexible match: Handles "Dr. Name" vs "Name"
          isMine = sched.contains(name) || 
                   name.contains(sched) ||
                   (sched.split(' ').length > 1 && name.contains(sched.split(' ').last));
        }
        
        return ScheduleItem.fromJson(json, isEnrolled: isMine);
      }).toList();

    } catch (e) {
      print('Fatal error in getLecturerTimetable: $e');
      return [];
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
