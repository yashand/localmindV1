// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      userId: json['user_id'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
      workHours: json['work_hours'] == null
          ? null
          : WorkHours.fromJson(json['work_hours'] as Map<String, dynamic>),
      privacySettings: json['privacy_settings'] == null
          ? null
          : PrivacySettings.fromJson(
              json['privacy_settings'] as Map<String, dynamic>),
      appUsage: (json['app_usage'] as List<dynamic>?)
              ?.map((e) => AppUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      locationData: (json['location_data'] as List<dynamic>?)
              ?.map((e) => LocationData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      habits: json['habits'] as Map<String, dynamic>? ?? const {},
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'preferences': instance.preferences,
      'work_hours': instance.workHours,
      'privacy_settings': instance.privacySettings,
      'app_usage': instance.appUsage,
      'location_data': instance.locationData,
      'habits': instance.habits,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

WorkHours _$WorkHoursFromJson(Map<String, dynamic> json) => WorkHours(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      workDays: (json['work_days'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      timezone: json['timezone'] as String,
    );

Map<String, dynamic> _$WorkHoursToJson(WorkHours instance) => <String, dynamic>{
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'work_days': instance.workDays,
      'timezone': instance.timezone,
    };

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      allowAppUsageTracking: json['allow_app_usage_tracking'] as bool? ?? false,
      allowLocationTracking: json['allow_location_tracking'] as bool? ?? false,
      allowCalendarAccess: json['allow_calendar_access'] as bool? ?? false,
      allowContactAccess: json['allow_contact_access'] as bool? ?? false,
      dataRetentionDays: (json['data_retention_days'] as num?)?.toInt() ?? 30,
      encryptLocalData: json['encrypt_local_data'] as bool? ?? true,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'allow_app_usage_tracking': instance.allowAppUsageTracking,
      'allow_location_tracking': instance.allowLocationTracking,
      'allow_calendar_access': instance.allowCalendarAccess,
      'allow_contact_access': instance.allowContactAccess,
      'data_retention_days': instance.dataRetentionDays,
      'encrypt_local_data': instance.encryptLocalData,
    };

AppUsage _$AppUsageFromJson(Map<String, dynamic> json) => AppUsage(
      packageName: json['package_name'] as String,
      appName: json['app_name'] as String,
      usageTimeMs: (json['usage_time_ms'] as num).toInt(),
      lastUsed: DateTime.parse(json['last_used'] as String),
      launchCount: (json['launch_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AppUsageToJson(AppUsage instance) => <String, dynamic>{
      'package_name': instance.packageName,
      'app_name': instance.appName,
      'usage_time_ms': instance.usageTimeMs,
      'last_used': instance.lastUsed.toIso8601String(),
      'launch_count': instance.launchCount,
    };

LocationData _$LocationDataFromJson(Map<String, dynamic> json) => LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
    );

Map<String, dynamic> _$LocationDataToJson(LocationData instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp.toIso8601String(),
      'address': instance.address,
    };