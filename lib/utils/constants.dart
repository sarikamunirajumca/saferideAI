import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

// Constants used throughout the app
class AppConstants {
  // App-wide settings
  static const String appName = 'SafeRide AI';
  
  // Monitoring thresholds (simplified for testing)
  static const double eyeClosureThreshold = 0.5; // Very lenient for testing
  static const double headPoseThreshold = 5.0; // Much more sensitive for testing
  static const int drowsinessFrameThreshold = 5; // Require 5 consecutive frames for stability
  static const int distractionFrameThreshold = 5; // Require 5 consecutive frames for stability
  
  // Advanced detection thresholds from car_ai
  static const double mouthAspectRatioThreshold = 0.5; // Very sensitive for testing
  static const double sleepRatioThreshold = 0.3; // Very sensitive for testing
  static const int sleepWindowFrames = 10; // Very fast for testing
  static const int headHistoryLength = 10; // Reduced for testing
  static const double motionSicknessThreshold = 3.0; // Very sensitive for testing
  
  // Alert cooldowns (in milliseconds) - Enhanced timing control
  static const int drowsinessAlertCooldown = 30000; // 30 seconds between drowsiness alerts
  static const int distractionAlertCooldown = 30000; // 30 seconds between distraction alerts
  static const int yawningAlertCooldown = 30000; // 30 seconds between yawning alerts
  static const int motionSicknessAlertCooldown = 30000; // 30 seconds between motion sickness alerts
  static const int seatbeltAlertCooldown = 30000; // 30 seconds between seatbelt alerts
  static const int phoneUsageAlertCooldown = 30000; // 30 seconds between phone usage alerts
  static const int erraticMovementAlertCooldown = 30000; // 30 seconds between erratic movement alerts
  
  // Processing delays (in milliseconds)
  static const int imageProcessingDelay = 200; // 200ms delay between image processing
  static const int alertDisplayDuration = 3000; // 3 seconds to display visual alerts
  static const int voiceAlertDelay = 500; // 500ms delay before voice alert
  static const int vibrationDelay = 100; // 100ms delay before vibration
  static const int startupDelay = 0; // No delay - start monitoring immediately
  
  // Consecutive frame requirements for stability
  static const int minConsecutiveFrames = 5; // Minimum consecutive frames before triggering alert
  
  // Camera settings
  static const int cameraFPS = 15;
  static const ResolutionPreset cameraResolution = ResolutionPreset.medium;
  
  // UI constants
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF4CAF50);
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
