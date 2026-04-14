import 'package:hive/hive.dart';

class CachedData<T> {
  CachedData({required this.data, required this.timestamp});

  final T data;
  final DateTime timestamp;

  bool get isExpired => DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

class CacheManager {
  static const Duration cacheExpiry = Duration(hours: 1);

  Future<T?> getCached<T>(String key) async {
    final box = await Hive.openBox('alerts_cache');
    final cached = box.get(key);
    if (cached != null && cached is CachedData && !cached.isExpired) {
      return cached.data as T;
    }
    return null;
  }

  Future<void> cache<T>(String key, T data) async {
    final box = await Hive.openBox('alerts_cache');
    await box.put(key, CachedData<T>(data: data, timestamp: DateTime.now()));
  }
}

