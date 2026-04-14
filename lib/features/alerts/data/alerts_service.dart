import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_service.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../models/alert_item.dart';

class AlertsService {
  AlertsService({
    SupabaseClient? client,
    OfflineService? offlineService,
    ConnectivityService? connectivityService,
  })  : _client = client ?? Supabase.instance.client,
        _offlineService = offlineService ?? OfflineService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  final SupabaseClient _client;
  final OfflineService _offlineService;
  final ConnectivityService _connectivityService;

  Future<List<AlertItem>> listLecturerAlerts({
    String? courseCode,
    AlertType? type,
    String search = '',
    String sort = 'deadline',
    int page = 0,
    int limit = 20,
  }) async {
    if (!SupabaseBootstrap.isConfigured) return [];

    try {
      final isOnline = await _connectivityService.isOnline();

      if (isOnline) {
        final FunctionResponse response = await _client.functions.invoke(
          'alerts-api',
          body: <String, dynamic>{
            'action': 'list_alerts',
            'course_code': courseCode,
            'type': type == null ? null : alertTypeToDb(type),
            'search': search,
            'sort': sort,
            'page': page,
            'limit': limit,
          },
        );

        if (response.status >= 400) {
          throw Exception(_extractError(response.data));
        }

        final Map<String, dynamic> payload = _asJsonMap(response.data);
        final List<dynamic> rows = (payload['alerts'] as List<dynamic>?) ?? <dynamic>[];
        final alerts = rows
            .map((dynamic row) => AlertItem.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList(growable: false);

        // Cache alerts for offline use
        if (page == 0 && search.isEmpty && courseCode == null) {
          await _offlineService.cacheAlerts(alerts.map((a) => a.toJson()).toList());
        }

        return alerts;
      } else {
        final cached = await _offlineService.getCachedAlerts();
        if (cached == null) {
          throw Exception('No internet and no cached data');
        }
        return cached.map((json) => AlertItem.fromJson(json)).toList();
      }
    } catch (e) {
      final cached = await _offlineService.getCachedAlerts();
      if (cached != null) {
        return cached.map((json) => AlertItem.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<AlertItem> getAlert(String alertId) async {
    _ensureConfigured();

    final FunctionResponse response = await _client.functions.invoke(
      'alerts-api',
      body: <String, dynamic>{'action': 'get_alert', 'alert_id': alertId},
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }

    final Map<String, dynamic> payload = _asJsonMap(response.data);
    final Map<String, dynamic> row = Map<String, dynamic>.from(
      (payload['alert'] as Map?) ?? <String, dynamic>{},
    );
    return AlertItem.fromJson(row);
  }

  Future<void> createAlert({
    required String title,
    required String description,
    required AlertType type,
    required String courseCode,
    DateTime? deadline,
    List<String> requirements = const <String>[],
  }) async {
    _ensureConfigured();

    final FunctionResponse response = await _client.functions.invoke(
      'alerts-api',
      body: <String, dynamic>{
        'action': 'create_alert',
        'title': title,
        'description': description,
        'type': alertTypeToDb(type),
        'course_code': courseCode,
        'deadline': deadline?.toUtc().toIso8601String(),
        'requirements': requirements,
      },
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }
  }

  Future<void> deleteAlert(String alertId) async {
    _ensureConfigured();

    final FunctionResponse response = await _client.functions.invoke(
      'alerts-api',
      body: <String, dynamic>{'action': 'delete_alert', 'alert_id': alertId},
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }
  }

  Future<void> updateAlertTitle({required String alertId, required String title}) async {
    _ensureConfigured();

    final FunctionResponse response = await _client.functions.invoke(
      'alerts-api',
      body: <String, dynamic>{
        'action': 'update_alert',
        'alert_id': alertId,
        'title': title,
      },
    );

    if (response.status >= 400) {
      throw Exception(_extractError(response.data));
    }
  }

  void _ensureConfigured() {
    if (!SupabaseBootstrap.isConfigured) {
      throw Exception('Supabase is not configured. Alerts require a live backend connection.');
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is String && payload.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return <String, dynamic>{'message': payload};
      }
    }
    return <String, dynamic>{};
  }

  String _extractError(dynamic payload) {
    final Map<String, dynamic> map = _asJsonMap(payload);
    final dynamic value = map['error'] ?? map['message'] ?? map['details'];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return 'Alert request failed. Please try again.';
  }
}

