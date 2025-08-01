import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Constants used throughout the app
class AppConstants {
  // App-wide settings
  static const String appName = 'SafeRide AI';
  
  // Monitoring thresholds (highly sensitive for real device testing)
  static const double eyeClosureThreshold = 0.6; // Very sensitive - eyes considered closed at 60% probability
  static const double headPoseThreshold = 15.0; // Very sensitive head pose threshold (15 degrees)
  static const int drowsinessFrameThreshold = 2; // Require only 2 consecutive frames for fastest response
  static const int distractionFrameThreshold = 2; // Require only 2 consecutive frames for fastest response
  
  // Advanced detection thresholds from car_ai (optimized for physical device)
  static const double mouthAspectRatioThreshold = 0.5; // Very sensitive for yawning detection
  static const double sleepRatioThreshold = 0.3; // Very sensitive for sleep detection
  static const int sleepWindowFrames = 3; // Fastest response for sleep detection
  static const int headHistoryLength = 5; // Faster tracking
  static const double motionSicknessThreshold = 1.5; // Very sensitive for motion sickness
  
  // Alert cooldowns (in milliseconds) - Very reduced for immediate testing
  static const int drowsinessAlertCooldown = 5000; // 5 seconds between drowsiness alerts
  static const int distractionAlertCooldown = 4000; // 4 seconds between distraction alerts
  static const int yawningAlertCooldown = 8000; // 8 seconds between yawning alerts
  static const int motionSicknessAlertCooldown = 6000; // 6 seconds between motion sickness alerts
  static const int seatbeltAlertCooldown = 10000; // 10 seconds between seatbelt alerts
  static const int phoneUsageAlertCooldown = 5000; // 5 seconds between phone usage alerts
  static const int erraticMovementAlertCooldown = 4000; // 4 seconds between erratic movement alerts
  
  // Processing delays (in milliseconds) - Optimized for better alert responsiveness
  static const int imageProcessingDelay = 200; // 200ms delay for better responsiveness
  static const int alertDisplayDuration = 5000; // 5 seconds to display visual alerts
  static const int voiceAlertDelay = 200; // 200ms delay before voice alert
  static const int vibrationDelay = 50; // 50ms delay before vibration
  static const int startupDelay = 0; // No delay - start monitoring immediately
  
  // Consecutive frame requirements for stability
  static const int minConsecutiveFrames = 5; // Minimum consecutive frames before triggering alert
  
  // Camera settings
  static const int cameraFPS = 15;
  static const ResolutionPreset cameraResolution = ResolutionPreset.medium;
  
  // UI constants - Dark theme colors
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  
  // Additional UI colors for modern design
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF1E2A3A);
  static const Color borderColor = Color(0xFF374151);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textMuted = Color(0xFF9CA3AF);
}

// Enum for the different types of detections
enum DetectionType {
  drowsiness,
  distraction,
  noSeatbelt,
  yawning,
  passengerDisturbance,
  motionSickness,
  phoneUsage,        // New from car_ai
  smokingDetection,  // New from car_ai
  erraticMovement,   // New from car_ai
}

// Shared preferences keys
class PreferenceKeys {
  static const String isDrowsinessDetectionEnabled = 'isDrowsinessDetectionEnabled';
  static const String isDistractionDetectionEnabled = 'isDistractionDetectionEnabled';
  static const String isSeatbeltDetectionEnabled = 'isSeatbeltDetectionEnabled';
  static const String isYawningDetectionEnabled = 'isYawningDetectionEnabled';
  static const String isPassengerMonitoringEnabled = 'isPassengerMonitoringEnabled';
  static const String isMotionSicknessDetectionEnabled = 'isMotionSicknessDetectionEnabled';
  
  // Advanced detection features from car_ai
  static const String isPhoneUsageDetectionEnabled = 'isPhoneUsageDetectionEnabled';
  static const String isSmokingDetectionEnabled = 'isSmokingDetectionEnabled';
  static const String isErraticMovementDetectionEnabled = 'isErraticMovementDetectionEnabled';
  static const String isVoiceAlertsEnabled = 'isVoiceAlertsEnabled';
  static const String isSeatbeltDetectionAdvancedEnabled = 'isSeatbeltDetectionAdvancedEnabled';
  
  // Advanced thresholds
  static const String earThreshold = 'earThreshold';
  static const String marThreshold = 'marThreshold';
  static const String motionSicknessThreshold = 'motionSicknessThreshold';
  
  static const String drowsinessThreshold = 'drowsinessThreshold';
  static const String distractionThreshold = 'distractionThreshold';
  static const String alertVolume = 'alertVolume';
  static const String isVibrationEnabled = 'isVibrationEnabled';
  static const String firstRun = 'firstRun';
}
