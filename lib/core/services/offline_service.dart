import 'package:hive_flutter/hive_flutter.dart';

class OfflineService {
  static const String COURSES_BOX = 'courses_cache';
  static const String LECTURES_BOX = 'lectures_cache';
  static const String NOTES_BOX = 'notes_cache';
  static const String ALERTS_BOX = 'alerts_cache';
  
  // Cache courses
  Future<void> cacheCourses(List<Map<String, dynamic>> courses) async {
    final box = await Hive.openBox(COURSES_BOX);
    await box.put('my_courses', courses);
    await box.put('last_synced', DateTime.now().toIso8601String());
  }
  
  // Get cached courses
  Future<List<Map<String, dynamic>>?> getCachedCourses() async {
    final box = await Hive.openBox(COURSES_BOX);
    final courses = box.get('my_courses');
    if (courses == null) return null;
    return (courses as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Cache notes
  Future<void> cacheNotes(String courseId, List<Map<String, dynamic>> notes) async {
    final box = await Hive.openBox(NOTES_BOX);
    await box.put('notes_$courseId', notes);
    await box.put('last_synced_$courseId', DateTime.now().toIso8601String());
  }

  // Get cached notes
  Future<List<Map<String, dynamic>>?> getCachedNotes(String courseId) async {
    final box = await Hive.openBox(NOTES_BOX);
    final notes = box.get('notes_$courseId');
    if (notes == null) return null;
    return (notes as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Cache alerts
  Future<void> cacheAlerts(List<Map<String, dynamic>> alerts) async {
    final box = await Hive.openBox(ALERTS_BOX);
    await box.put('my_alerts', alerts);
    await box.put('last_synced', DateTime.now().toIso8601String());
  }

  // Get cached alerts
  Future<List<Map<String, dynamic>>?> getCachedAlerts() async {
    final box = await Hive.openBox(ALERTS_BOX);
    final alerts = box.get('my_alerts');
    if (alerts == null) return null;
    return (alerts as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  
  // Check if data is stale (older than 1 hour)
  Future<bool> isCacheStale() async {
    final box = await Hive.openBox(COURSES_BOX);
    final lastSynced = box.get('last_synced');
    if (lastSynced == null) return true;
    
    final syncTime = DateTime.parse(lastSynced);
    final diff = DateTime.now().difference(syncTime);
    return diff.inHours > 1;
  }
  
  // Clear all cache
  Future<void> clearCache() async {
    await Hive.deleteBoxFromDisk(COURSES_BOX);
    await Hive.deleteBoxFromDisk(LECTURES_BOX);
    await Hive.deleteBoxFromDisk(NOTES_BOX);
    await Hive.deleteBoxFromDisk(ALERTS_BOX);
  }
}
