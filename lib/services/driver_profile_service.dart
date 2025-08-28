import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfile {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
  final Map<String, int> detectionCounts;
  final double safetyScore;

  DriverProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.createdAt,
    required this.preferences,
    required this.detectionCounts,
    this.safetyScore = 100.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
      'detectionCounts': detectionCounts,
      'safetyScore': safetyScore,
    };
  }

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      preferences: Map<String, dynamic>.from(json['preferences']),
      detectionCounts: Map<String, int>.from(json['detectionCounts']),
      safetyScore: json['safetyScore']?.toDouble() ?? 100.0,
    );
  }
}

class DriverProfileService {
  static const String _profilesKey = 'driver_profiles';
  static const String _currentProfileKey = 'current_profile_id';

  static Future<List<DriverProfile>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString(_profilesKey);
    
    if (profilesJson == null) return [];
    
    final List<dynamic> profilesList = json.decode(profilesJson);
    return profilesList.map((json) => DriverProfile.fromJson(json)).toList();
  }

  static Future<void> saveProfile(DriverProfile profile) async {
    final profiles = await getProfiles();
    final existingIndex = profiles.indexWhere((p) => p.id == profile.id);
    
    if (existingIndex >= 0) {
      profiles[existingIndex] = profile;
    } else {
      profiles.add(profile);
    }
    
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, profilesJson);
  }

  static Future<void> deleteProfile(String profileId) async {
    final profiles = await getProfiles();
    profiles.removeWhere((p) => p.id == profileId);
    
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = json.encode(profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, profilesJson);
  }

  static Future<DriverProfile?> getCurrentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getString(_currentProfileKey);
    
    if (currentId == null) return null;
    
    final profiles = await getProfiles();
    return profiles.where((p) => p.id == currentId).firstOrNull;
  }

  static Future<void> setCurrentProfile(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentProfileKey, profileId);
  }

  static Future<DriverProfile> createDefaultProfile(String name, String email) async {
    final profile = DriverProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
      preferences: {
        'alertVolume': 80,
        'voiceAlerts': true,
        'vibrationAlerts': true,
        'sensitivity': 'medium',
        'autoStart': false,
        'nightMode': false,
        'breakReminders': true,
        'breakInterval': 120, // minutes
      },
      detectionCounts: {
        'drowsiness': 0,
        'distraction': 0,
        'yawning': 0,
        'phoneUsage': 0,
        'motionSickness': 0,
        'erraticMovement': 0,
      },
    );
    
    await saveProfile(profile);
    await setCurrentProfile(profile.id);
    return profile;
  }

  static Future<void> updateDetectionCount(String type) async {
    final profile = await getCurrentProfile();
    if (profile == null) return;

    final updatedCounts = Map<String, int>.from(profile.detectionCounts);
    updatedCounts[type] = (updatedCounts[type] ?? 0) + 1;

    // Recalculate safety score
    final totalDetections = updatedCounts.values.fold<int>(0, (sum, count) => sum + count);
    final newSafetyScore = (100.0 - (totalDetections * 2)).clamp(0.0, 100.0);

    final updatedProfile = DriverProfile(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      photoUrl: profile.photoUrl,
      createdAt: profile.createdAt,
      preferences: profile.preferences,
      detectionCounts: updatedCounts,
      safetyScore: newSafetyScore,
    );

    await saveProfile(updatedProfile);
  }
}
