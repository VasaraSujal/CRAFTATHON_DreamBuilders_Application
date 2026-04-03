import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

class AppDataProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _trafficSeries = [];
  List<Map<String, dynamic>> _liveTraffic = [];
  List<Map<String, dynamic>> _rawAlerts = [];
  List<Map<String, dynamic>> _recentAlerts = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _statsApi;
  bool _loading = true;
  String _error = '';
  bool _isTrackingLive = true;
  Timer? _refreshTimer;
  String? _lastLiveId;

  Map<String, dynamic> _settings = {
    'alertThreshold': 50,
    'refreshInterval': 5,
    'theme': 'dark',
  };

  List<Map<String, dynamic>> _notifications = [];

  // Getters
  List<Map<String, dynamic>> get trafficSeries => _trafficSeries;
  List<Map<String, dynamic>> get liveTraffic => _liveTraffic;
  List<Map<String, dynamic>> get recentAlerts => _recentAlerts;
  List<Map<String, dynamic>> get logs => _logs;
  bool get loading => _loading;
  String get error => _error;
  bool get isTrackingLive => _isTrackingLive;
  Map<String, dynamic> get settings => _settings;
  List<Map<String, dynamic>> get notifications => _notifications;

  List<Map<String, dynamic>> get alerts {
    final threshold = (_settings['alertThreshold'] as int?) ?? 50;
    return _rawAlerts.where((a) {
      return _severityRank(a['severity'] as String? ?? '') >= threshold;
    }).toList();
  }

  Map<String, dynamic> get stats {
    final totalTraffic = _statsApi?['totalTraffic'] ?? _logs.length;

    int anomalies;
    final trafficByStatus = _statsApi?['trafficByStatus'] as List?;
    if (trafficByStatus != null) {
      final anomalyEntry = trafficByStatus.firstWhere(
        (x) => x['_id'] == 'Anomaly',
        orElse: () => null,
      );
      anomalies = anomalyEntry?['count'] ?? 0;
    } else {
      anomalies = _logs.where((item) => item['status'] == 'Anomaly').length;
    }

    final activeNodes = <String>{};
    for (final item in _logs) {
      if (item['source'] != null) activeNodes.add(item['source'] as String);
      if (item['destination'] != null) activeNodes.add(item['destination'] as String);
    }

    final latest = _trafficSeries.isNotEmpty
        ? _trafficSeries.last
        : {'normal': 1, 'attack': 0};
    final normal = (latest['normal'] as int?) ?? 1;
    final attack = (latest['attack'] as int?) ?? 0;
    final total = normal + attack;
    final attackPercent = total > 0 ? (attack * 100 / total).round() : 0;

    String systemStatus = 'Normal';
    if (attackPercent >= 30) {
      systemStatus = 'Critical';
    } else if (attackPercent >= 15) {
      systemStatus = 'Warning';
    }

    return {
      'totalTraffic': totalTraffic,
      'anomalies': anomalies,
      'activeNodes': activeNodes.length,
      'attackPercent': attackPercent,
      'systemStatus': systemStatus,
      'normalTraffic': normal,
      'attackTraffic': attack,
    };
  }

  int _severityRank(String level) {
    switch (level) {
      case 'Critical':
        return 100;
      case 'High':
        return 75;
      case 'Medium':
        return 50;
      case 'Low':
        return 25;
      default:
        return 0;
    }
  }

  AppDataProvider() {
    _loadSettings();
    _loadStoredTraffic();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKeySettings);
      if (raw != null) {
        _settings = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadStoredTraffic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKeyTraffic);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _liveTraffic = list.cast<Map<String, dynamic>>();
        _logs = List.from(_liveTraffic);
      }
    } catch (_) {
      // ignore
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    if (!_isTrackingLive) return;
    final interval = (_settings['refreshInterval'] as int?) ?? 5;
    _refreshTimer = Timer.periodic(
      Duration(seconds: interval.clamp(1, 60)),
      (_) => refreshData(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  void toggleTracking() {
    _isTrackingLive = !_isTrackingLive;
    if (_isTrackingLive) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
    notifyListeners();
  }

  Future<void> refreshData({bool silent = true}) async {
    if (!_isTrackingLive && silent) return;

    if (!silent) {
      _loading = true;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        ApiService.fetchLiveTraffic(),
        ApiService.fetchAlerts(),
        ApiService.fetchStats(),
      ]);

      final liveRow = results[0] as Map<String, dynamic>?;
      final alertRows = (results[1] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [];
      final statsRows = results[2] as Map<String, dynamic>?;

      _error = '';
      _rawAlerts = alertRows;
      _statsApi = statsRows;

      if (liveRow != null && liveRow['_id'] != _lastLiveId) {
        _lastLiveId = liveRow['_id'] as String?;

        _liveTraffic = [liveRow, ..._liveTraffic];
        if (_liveTraffic.length > 200) {
          _liveTraffic = _liveTraffic.sublist(0, 200);
        }
        _logs = List.from(_liveTraffic);
        _trafficSeries = _rebuildSeries(_liveTraffic);

        _persistLocalTraffic();

        if (liveRow['status'] == 'Anomaly') {
          final severity = (liveRow['severity'] as String?) ?? 'Medium';
          final attackType = liveRow['attackType'] as String?;
          final message = attackType != null
              ? '$attackType detected from ${liveRow['source']}'
              : 'Anomaly detected';

          _recentAlerts = [
            {
              'id': liveRow['_id'],
              'message': message,
              'severity': severity,
              'timestamp': DateTime.now().toIso8601String(),
              'source': liveRow['source'],
              'destination': liveRow['destination'],
            },
            ..._recentAlerts,
          ];
          if (_recentAlerts.length > 10) {
            _recentAlerts = _recentAlerts.sublist(0, 10);
          }

          _pushNotification(message, severity);
        }
      } else {
        _logs = List.from(_liveTraffic);
        _trafficSeries = _rebuildSeries(_liveTraffic);
      }
    } catch (e) {
      _error = 'Unable to fetch real-time data from backend';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _rebuildSeries(List<Map<String, dynamic>> trafficRows) {
    final ordered = trafficRows.reversed.toList();
    final map = <String, Map<String, dynamic>>{};

    for (final row in ordered) {
      final timestamp = row['timestamp'] as String?;
      DateTime dt;
      try {
        dt = timestamp != null ? DateTime.parse(timestamp) : DateTime.now();
      } catch (_) {
        dt = DateTime.now();
      }
      final key = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      final current = map[key] ?? {'time': key, 'normal': 0, 'attack': 0, 'total': 0};
      if (row['status'] == 'Anomaly') {
        current['attack'] = (current['attack'] as int) + 1;
      } else {
        current['normal'] = (current['normal'] as int) + 1;
      }
      current['total'] = (current['total'] as int) + 1;
      map[key] = current;
    }

    final values = map.values.toList();
    return values.length > 12 ? values.sublist(values.length - 12) : values;
  }

  Future<void> _persistLocalTraffic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKeyTraffic, jsonEncode(_liveTraffic));
    } catch (_) {
      // ignore
    }
  }

  void _pushNotification(String message, String severity) {
    final id = 'ntf-${DateTime.now().millisecondsSinceEpoch}';
    _notifications = [
      {'id': id, 'message': message, 'severity': severity},
      ..._notifications,
    ];
    if (_notifications.length > 4) {
      _notifications = _notifications.sublist(0, 4);
    }
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 3500), () {
      _notifications = _notifications.where((n) => n['id'] != id).toList();
      notifyListeners();
    });
  }

  Future<void> runSimulation(String type) async {
    await ApiService.simulateTraffic(type);
    await refreshData(silent: false);
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    _settings = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKeySettings, jsonEncode(_settings));

    // Restart auto refresh with new interval
    startAutoRefresh();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
