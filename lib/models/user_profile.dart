import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile extends ChangeNotifier {
  @JsonKey(name: 'user_id')
  String? userId;
  
  @JsonKey(name: 'preferences')
  Map<String, dynamic> preferences;
  
  @JsonKey(name: 'work_hours')
  WorkHours? workHours;
  
  @JsonKey(name: 'privacy_settings')
  PrivacySettings privacySettings;
  
  @JsonKey(name: 'app_usage')
  List<AppUsage> appUsage;
  
  @JsonKey(name: 'location_data')
  List<LocationData> locationData;
  
  @JsonKey(name: 'habits')
  Map<String, dynamic> habits;
  
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  UserProfile({
    this.userId,
    this.preferences = const {},
    this.workHours,
    PrivacySettings? privacySettings,
    this.appUsage = const [],
    this.locationData = const [],
    this.habits = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : privacySettings = privacySettings ?? PrivacySettings(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) => 
      _$UserProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  
  void updatePreference(String key, dynamic value) {
    preferences[key] = value;
    updatedAt = DateTime.now();
    notifyListeners();
  }
  
  void addAppUsage(AppUsage usage) {
    appUsage.add(usage);
    updatedAt = DateTime.now();
    notifyListeners();
  }
  
  void addLocationData(LocationData location) {
    locationData.add(location);
    updatedAt = DateTime.now();
    notifyListeners();
  }
  
  void updateHabit(String habitName, dynamic data) {
    habits[habitName] = data;
    updatedAt = DateTime.now();
    notifyListeners();
  }
  
  void setWorkHours(WorkHours hours) {
    workHours = hours;
    updatedAt = DateTime.now();
    notifyListeners();
  }
  
  void updatePrivacySettings(PrivacySettings settings) {
    privacySettings = settings;
    updatedAt = DateTime.now();
    notifyListeners();
  }
}

@JsonSerializable()
class WorkHours {
  @JsonKey(name: 'start_time')
  String startTime; // Format: "09:00"
  
  @JsonKey(name: 'end_time')
  String endTime; // Format: "17:00"
  
  @JsonKey(name: 'work_days')
  List<int> workDays; // 1-7, Monday-Sunday
  
  @JsonKey(name: 'timezone')
  String timezone;

  WorkHours({
    required this.startTime,
    required this.endTime,
    required this.workDays,
    required this.timezone,
  });

  factory WorkHours.fromJson(Map<String, dynamic> json) => 
      _$WorkHoursFromJson(json);
  
  Map<String, dynamic> toJson() => _$WorkHoursToJson(this);
}

@JsonSerializable()
class PrivacySettings {
  @JsonKey(name: 'allow_app_usage_tracking')
  bool allowAppUsageTracking;
  
  @JsonKey(name: 'allow_location_tracking')
  bool allowLocationTracking;
  
  @JsonKey(name: 'allow_calendar_access')
  bool allowCalendarAccess;
  
  @JsonKey(name: 'allow_contact_access')
  bool allowContactAccess;
  
  @JsonKey(name: 'data_retention_days')
  int dataRetentionDays;
  
  @JsonKey(name: 'encrypt_local_data')
  bool encryptLocalData;

  PrivacySettings({
    this.allowAppUsageTracking = false,
    this.allowLocationTracking = false,
    this.allowCalendarAccess = false,
    this.allowContactAccess = false,
    this.dataRetentionDays = 30,
    this.encryptLocalData = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => 
      _$PrivacySettingsFromJson(json);
  
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);
}

@JsonSerializable()
class AppUsage {
  @JsonKey(name: 'package_name')
  String packageName;
  
  @JsonKey(name: 'app_name')
  String appName;
  
  @JsonKey(name: 'usage_time_ms')
  int usageTimeMs;
  
  @JsonKey(name: 'last_used')
  DateTime lastUsed;
  
  @JsonKey(name: 'launch_count')
  int launchCount;

  AppUsage({
    required this.packageName,
    required this.appName,
    required this.usageTimeMs,
    required this.lastUsed,
    this.launchCount = 0,
  });

  factory AppUsage.fromJson(Map<String, dynamic> json) => 
      _$AppUsageFromJson(json);
  
  Map<String, dynamic> toJson() => _$AppUsageToJson(this);
}

@JsonSerializable()
class LocationData {
  @JsonKey(name: 'latitude')
  double latitude;
  
  @JsonKey(name: 'longitude')
  double longitude;
  
  @JsonKey(name: 'accuracy')
  double accuracy;
  
  @JsonKey(name: 'timestamp')
  DateTime timestamp;
  
  @JsonKey(name: 'address')
  String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.address,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) => 
      _$LocationDataFromJson(json);
  
  Map<String, dynamic> toJson() => _$LocationDataToJson(this);
}