import 'package:hive_flutter/hive_flutter.dart';

class OfflineService {
  static const String coursesBox = 'courses_cache';
  static const String lecturesBox = 'lectures_cache';
  static const String notesBox = 'notes_cache';
  static const String alertsBox = 'alerts_cache';
  static const String timetableBox = 'timetable_cache';
  
  // Cache timetable
  Future<void> cacheTimetable(List<Map<String, dynamic>> schedules) async {
    final box = await Hive.openBox(timetableBox);
    await box.put('timetable', schedules);
    await box.put('last_synced', DateTime.now().toIso8601String());
  }

  // Get cached timetable
  Future<List<Map<String, dynamic>>?> getCachedTimetable() async {
    final box = await Hive.openBox(timetableBox);
    final schedules = box.get('timetable');
    if (schedules == null) return null;
    return (schedules as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  
  // Cache courses
  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    final box = await Hive.openBox(coursesBox);
    await box.put('my_courses', courses);
    await box.put('last_synced', DateTime.now().toIso8601String());
  }
  
  // Get cached courses
  Future<List<Map<String, dynamic>>?> getCachedCourses() async {
    final box = await Hive.openBox(coursesBox);
    final courses = box.get('my_courses');
    if (courses == null) return null;
    return (courses as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Cache notes
  Future<void> cacheNotes(String courseId, List<Map<String, dynamic>> notes) async {
    final box = await Hive.openBox(notesBox);
    await box.put('notes_$courseId', notes);
    await box.put('last_synced_$courseId', DateTime.now().toIso8601String());
  }

  // Get cached notes
  Future<List<Map<String, dynamic>>?> getCachedNotes(String courseId) async {
    final box = await Hive.openBox(notesBox);
    final notes = box.get('notes_$courseId');
    if (notes == null) return null;
    return (notes as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Cache alerts
  Future<void> cacheAlerts(List<Map<String, dynamic>> alerts) async {
    final box = await Hive.openBox(alertsBox);
    await box.put('my_alerts', alerts);
    await box.put('last_synced', DateTime.now().toIso8601String());
  }

  // Get cached alerts
  Future<List<Map<String, dynamic>>?> getCachedAlerts() async {
    final box = await Hive.openBox(alertsBox);
    final alerts = box.get('my_alerts');
    if (alerts == null) return null;
    return (alerts as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  
  // Check if data is stale (older than 1 hour)
  Future<bool> isCacheStale() async {
    final box = await Hive.openBox(coursesBox);
    final lastSynced = box.get('last_synced');
    if (lastSynced == null) return true;
    
    final syncTime = DateTime.parse(lastSynced);
    final diff = DateTime.now().difference(syncTime);
    return diff.inHours > 1;
  }
  
  // Clear all cache
  Future<void> clearCache() async {
    await Hive.deleteBoxFromDisk(coursesBox);
    await Hive.deleteBoxFromDisk(lecturesBox);
    await Hive.deleteBoxFromDisk(notesBox);
    await Hive.deleteBoxFromDisk(alertsBox);
  }
}
