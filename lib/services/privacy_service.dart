import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/user_profile.dart';

class PrivacyService {
  static const String _accessLogKey = 'privacy_access_log';
  static const String _consentKey = 'privacy_consent';
  
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();
  
  List<PrivacyAccessLog> _accessLogs = [];
  Map<String, bool> _consents = {};

  PrivacyService(this._storage);

  List<PrivacyAccessLog> get accessLogs => List.unmodifiable(_accessLogs);
  Map<String, bool> get consents => Map.unmodifiable(_consents);

  Future<void> initialize() async {
    await _loadAccessLogs();
    await _loadConsents();
  }

  Future<bool> requestPermission(String dataType, String purpose) async {
    final consentKey = '${dataType}_$purpose';
    
    // Check if consent already exists
    if (_consents.containsKey(consentKey)) {
      return _consents[consentKey]!;
    }
    
    // Log the permission request
    await logDataAccess(dataType, 'permission_requested', {
      'purpose': purpose,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // In a real app, this would show a consent dialog
    // For now, default to false (no consent)
    _consents[consentKey] = false;
    await _saveConsents();
    
    return false;
  }

  Future<void> grantPermission(String dataType, String purpose) async {
    final consentKey = '${dataType}_$purpose';
    _consents[consentKey] = true;
    await _saveConsents();
    
    await logDataAccess(dataType, 'permission_granted', {
      'purpose': purpose,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> revokePermission(String dataType, String purpose) async {
    final consentKey = '${dataType}_$purpose';
    _consents[consentKey] = false;
    await _saveConsents();
    
    await logDataAccess(dataType, 'permission_revoked', {
      'purpose': purpose,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logDataAccess(String dataType, String action, Map<String, dynamic>? metadata) async {
    final log = PrivacyAccessLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      dataType: dataType,
      action: action,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _accessLogs.add(log);
    await _saveAccessLogs();
    
    _logger.i('Privacy access logged: $dataType - $action');
  }

  Future<void> deleteDataType(String dataType) async {
    // Remove access logs for this data type
    _accessLogs.removeWhere((log) => log.dataType == dataType);
    await _saveAccessLogs();
    
    // Remove consents for this data type
    _consents.removeWhere((key, value) => key.startsWith(dataType));
    await _saveConsents();
    
    await logDataAccess(dataType, 'data_deleted', {
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _logger.i('Data deleted for type: $dataType');
  }

  Future<void> clearAllData() async {
    _accessLogs.clear();
    _consents.clear();
    
    await _storage.delete(key: _accessLogKey);
    await _storage.delete(key: _consentKey);
    
    _logger.i('All privacy data cleared');
  }

  List<PrivacyAccessLog> getAccessLogsForDataType(String dataType) {
    return _accessLogs.where((log) => log.dataType == dataType).toList();
  }

  List<PrivacyAccessLog> getRecentAccessLogs({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _accessLogs.where((log) => log.timestamp.isAfter(cutoff)).toList();
  }

  Map<String, int> getDataAccessSummary({int days = 7}) {
    final recentLogs = getRecentAccessLogs(days: days);
    final summary = <String, int>{};
    
    for (final log in recentLogs) {
      summary[log.dataType] = (summary[log.dataType] ?? 0) + 1;
    }
    
    return summary;
  }

  Future<void> _loadAccessLogs() async {
    try {
      final data = await _storage.read(key: _accessLogKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _accessLogs = jsonList.map((json) => PrivacyAccessLog.fromJson(json)).toList();
      }
    } catch (e) {
      _logger.e('Failed to load access logs: $e');
      _accessLogs = [];
    }
  }

  Future<void> _saveAccessLogs() async {
    try {
      final jsonList = _accessLogs.map((log) => log.toJson()).toList();
      await _storage.write(key: _accessLogKey, value: jsonEncode(jsonList));
    } catch (e) {
      _logger.e('Failed to save access logs: $e');
    }
  }

  Future<void> _loadConsents() async {
    try {
      final data = await _storage.read(key: _consentKey);
      if (data != null) {
        _consents = Map<String, bool>.from(jsonDecode(data));
      }
    } catch (e) {
      _logger.e('Failed to load consents: $e');
      _consents = {};
    }
  }

  Future<void> _saveConsents() async {
    try {
      await _storage.write(key: _consentKey, value: jsonEncode(_consents));
    } catch (e) {
      _logger.e('Failed to save consents: $e');
    }
  }
}

class PrivacyAccessLog {
  final String id;
  final String dataType;
  final String action;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PrivacyAccessLog({
    required this.id,
    required this.dataType,
    required this.action,
    required this.timestamp,
    required this.metadata,
  });

  factory PrivacyAccessLog.fromJson(Map<String, dynamic> json) {
    return PrivacyAccessLog(
      id: json['id'],
      dataType: json['data_type'],
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data_type': dataType,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}