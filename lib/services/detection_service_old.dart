import 'dart:async';
import 'dart:math' as math;
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:saferide_ai_app/models/detection_model.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class DetectionService extends ChangeNotifier {
  // ML models
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  
  // Detection state
  bool isRunning = false;
  String? currentAlert; // Add current alert message
  int consecutiveDrowsyFrames = 0;
  int consecutiveDistractionFrames = 0;
  DateTime? lastDrowsinessAlert;
  DateTime? lastDistractionAlert;
  DateTime? lastYawningAlert;
  DateTime? lastMotionSicknessAlert;
  DateTime? lastSeatbeltAlert;
  DateTime? lastPhoneUsageAlert;
  DateTime? lastSmokingAlert;
  DateTime? lastErraticMovementAlert;
  
  // Advanced detection state from car_ai
  Queue<double> earHistory = Queue<double>();
  Queue<List<double>> headPoseHistory = Queue<List<double>>();
  Queue<double> marHistory = Queue<double>();
  int alertTriggeredFrame = 0;
  
  // Detection settings
  bool isDrowsinessDetectionEnabled = true;
  bool isDistractionDetectionEnabled = true;
  bool isSeatbeltDetectionEnabled = true;
  bool isYawningDetectionEnabled = true;
  bool isPassengerMonitoringEnabled = true;
  bool isMotionSicknessDetectionEnabled = false;
  bool isPhoneUsageDetectionEnabled = false;
  bool isSmokingDetectionEnabled = false;
  bool isErraticMovementDetectionEnabled = true;
  
  // Voice alert system
  final FlutterTts _flutterTts = FlutterTts();
  bool isVoiceAlertsEnabled = true;
  bool _isSpeaking = false;
  
  // Detection history
  final DetectionHistory _detectionHistory = DetectionHistory();
  final DetectionStats _detectionStats = DetectionStats();
  
  // Alert cooldowns (in milliseconds)
  static const int alertCooldown = 10000; // 10 seconds
  
  // Getters
  DetectionHistory get detectionHistory => _detectionHistory;
  DetectionStats get detectionStats => _detectionStats;
  
  DetectionService() {
    _loadSettings();
    _initializeTTS();
  }
  
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.8); // Slightly slower for clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('TTS initialization failed: $e');
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    isDrowsinessDetectionEnabled = prefs.getBool(PreferenceKeys.isDrowsinessDetectionEnabled) ?? true;
    isDistractionDetectionEnabled = prefs.getBool(PreferenceKeys.isDistractionDetectionEnabled) ?? true;
    isSeatbeltDetectionEnabled = prefs.getBool(PreferenceKeys.isSeatbeltDetectionEnabled) ?? true;
    isYawningDetectionEnabled = prefs.getBool(PreferenceKeys.isYawningDetectionEnabled) ?? true;
    isPassengerMonitoringEnabled = prefs.getBool(PreferenceKeys.isPassengerMonitoringEnabled) ?? true;
    isMotionSicknessDetectionEnabled = prefs.getBool(PreferenceKeys.isMotionSicknessDetectionEnabled) ?? false;
    isPhoneUsageDetectionEnabled = prefs.getBool(PreferenceKeys.isPhoneUsageDetectionEnabled) ?? false;
    isSmokingDetectionEnabled = prefs.getBool(PreferenceKeys.isSmokingDetectionEnabled) ?? false;
    isErraticMovementDetectionEnabled = prefs.getBool(PreferenceKeys.isErraticMovementDetectionEnabled) ?? true;
    isVoiceAlertsEnabled = prefs.getBool(PreferenceKeys.isVoiceAlertsEnabled) ?? true;
    
    notifyListeners();
  }
  
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(PreferenceKeys.isDrowsinessDetectionEnabled, isDrowsinessDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isDistractionDetectionEnabled, isDistractionDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isSeatbeltDetectionEnabled, isSeatbeltDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isYawningDetectionEnabled, isYawningDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isPassengerMonitoringEnabled, isPassengerMonitoringEnabled);
    await prefs.setBool(PreferenceKeys.isMotionSicknessDetectionEnabled, isMotionSicknessDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isPhoneUsageDetectionEnabled, isPhoneUsageDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isSmokingDetectionEnabled, isSmokingDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isErraticMovementDetectionEnabled, isErraticMovementDetectionEnabled);
    await prefs.setBool(PreferenceKeys.isVoiceAlertsEnabled, isVoiceAlertsEnabled);
  }
  
  Future<void> processImage(InputImage inputImage) async {
    if (!isRunning) return;
    
    try {
      // ML Kit face detection is disabled for YUV420 compatibility
      // This improves performance significantly while we focus on video streaming
      
      // Minimal logging to avoid spam (only log once every 5 seconds)
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        debugPrint('⏰ Processing image... Running: $isRunning');
      }
      
      // No face detection processing to improve performance
      // Face detection will be re-enabled once we implement proper YUV420→BGRA8888 conversion
      
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }
  
  // Advanced Distraction Detection (from car_ai)
  Future<bool> _detectAdvancedDistraction(Face face) async {
    if (face.headEulerAngleX != null && 
        face.headEulerAngleY != null && 
        face.headEulerAngleZ != null) {
      
      final pitch = face.headEulerAngleX!.abs();
      final yaw = face.headEulerAngleY!.abs();
      
      debugPrint('Head pose - Pitch: ${pitch.toStringAsFixed(1)}°, Yaw: ${yaw.toStringAsFixed(1)}°, Threshold: ${AppConstants.headPoseThreshold}°');
      
      // Check if head is turned beyond threshold
      if (yaw > AppConstants.headPoseThreshold || pitch > AppConstants.headPoseThreshold) {
        consecutiveDistractionFrames++;
        debugPrint('Distraction detected! Consecutive frames: $consecutiveDistractionFrames/${AppConstants.distractionFrameThreshold}');
        
        if (consecutiveDistractionFrames >= AppConstants.distractionFrameThreshold) {
          final now = DateTime.now();
          if (lastDistractionAlert == null || 
              now.difference(lastDistractionAlert!).inMilliseconds > AppConstants.distractionAlertCooldown) {
            
            _showAlert("Driver distracted! Please focus on the road!");
            
            final detection = DetectionResult(
              type: DetectionType.distraction,
              confidence: math.max(yaw, pitch) / 90.0,
              timestamp: now,
            );
            
            _detectionHistory.addDetection(detection);
            _detectionStats.incrementDetection(DetectionType.distraction);
            lastDistractionAlert = now;
            consecutiveDistractionFrames = 0;
            notifyListeners();
            return true;
          }
        }
      } else {
        consecutiveDistractionFrames = 0;
      }
    } else {
      debugPrint('Head pose data not available');
    }
    return false;
  }
  
  // Advanced Yawning Detection (from car_ai using MAR)
  Future<bool> _detectAdvancedYawning(Face face) async {
    // Since ML Kit doesn't provide direct mouth landmarks, we use smile probability as proxy
    // In a full implementation, we would calculate Mouth Aspect Ratio (MAR)
    final mouthOpenness = face.smilingProbability ?? 0.0;
    
    // Invert smiling probability to approximate mouth opening
    final mar = 1.0 - mouthOpenness;
    
    marHistory.add(mar);
    if (marHistory.length > 10) { // Keep last 10 frames
      marHistory.removeFirst();
    }
    
    // Check if mouth is significantly open
    if (mar > AppConstants.mouthAspectRatioThreshold) {
      final now = DateTime.now();
      if (lastYawningAlert == null || 
          now.difference(lastYawningAlert!).inMilliseconds > AppConstants.yawningAlertCooldown) {
        
        _showAlert("Yawning detected! Driver appears tired. Consider taking a break.");
        
        final detection = DetectionResult(
          type: DetectionType.yawning,
          confidence: mar,
          timestamp: now,
        );
        
        _detectionHistory.addDetection(detection);
        _detectionStats.incrementDetection(DetectionType.yawning);
        lastYawningAlert = now;
        notifyListeners();
        return true;
      }
    }
    return false;
  }
  
  // Motion Sickness Detection (from car_ai)
  Future<bool> _detectMotionSickness(Face face) async {
    if (face.headEulerAngleX != null && 
        face.headEulerAngleY != null && 
        face.headEulerAngleZ != null) {
      
      final headPose = [
        face.headEulerAngleX!,
        face.headEulerAngleY!,
        face.headEulerAngleZ!
      ];
      
      headPoseHistory.add(headPose);
      if (headPoseHistory.length > AppConstants.headHistoryLength) {
        headPoseHistory.removeFirst();
      }
      
      if (headPoseHistory.length >= AppConstants.headHistoryLength) {
        // Calculate standard deviation for each axis
        final pitchValues = headPoseHistory.map((pose) => pose[0]).toList();
        final yawValues = headPoseHistory.map((pose) => pose[1]).toList();
        final rollValues = headPoseHistory.map((pose) => pose[2]).toList();
        
        final pitchStd = _calculateStandardDeviation(pitchValues);
        final yawStd = _calculateStandardDeviation(yawValues);
        final rollStd = _calculateStandardDeviation(rollValues);
        
        // Check for erratic movement
        if (pitchStd > AppConstants.motionSicknessThreshold || 
            yawStd > AppConstants.motionSicknessThreshold || 
            rollStd > AppConstants.motionSicknessThreshold) {
          
          final now = DateTime.now();
          if (lastMotionSicknessAlert == null || 
              now.difference(lastMotionSicknessAlert!).inMilliseconds > AppConstants.motionSicknessAlertCooldown) {
            
            _showAlert("Erratic head movement detected! Possible motion sickness or distress.");
            
            final detection = DetectionResult(
              type: DetectionType.motionSickness,
              confidence: math.max(pitchStd, math.max(yawStd, rollStd)) / 20.0,
              timestamp: now,
            );
            
            _detectionHistory.addDetection(detection);
            _detectionStats.incrementDetection(DetectionType.motionSickness);
            lastMotionSicknessAlert = now;
            notifyListeners();
            return true;
          }
        }
      }
    }
    return false;
  }
  
  // Phone Usage Detection (placeholder - would need additional computer vision)
  Future<bool> _detectPhoneUsage(Face face) async {
    // This would require additional object detection models
    // For now, return false as placeholder
    return false;
  }
  
  // Smoking Detection (placeholder - would need additional computer vision)
  Future<bool> _detectSmoking(Face face) async {
    // This would require additional object detection models
    // For now, return false as placeholder
    return false;
  }
  
  // Seatbelt Detection (placeholder - would need additional computer vision)
  Future<bool> _detectSeatbelt(Face face) async {
    // This would require additional computer vision for shoulder/body analysis
    // For now, return false as placeholder
    return false;
  }
  
  // Helper method to calculate standard deviation
  double _calculateStandardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((value) => math.pow(value - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
  
  void _showAlert(String message) {
    debugPrint("ALERT: $message");
    
    // Set current alert for UI to display
    currentAlert = message;
    
    // Show visual alert
    _showVisualAlert(message);
    
    // Trigger voice alert if enabled
    _triggerVoiceAlert(message);
    
    // Trigger vibration if enabled
    _triggerVibration();
    
    // Notify listeners so UI can update
    notifyListeners();
    
    // Clear alert after 5 seconds (extended for voice alert)
    Timer(Duration(seconds: 5), () {
      currentAlert = null;
      notifyListeners();
    });
  }
  
  void _showVisualAlert(String message) {
    // This will be handled by the UI layer through the listener pattern
    // The UI will listen to detection changes and show appropriate alerts
    debugPrint("Visual Alert: $message");
  }
  
  void _triggerVibration() {
    // Trigger vibration for alerts
    debugPrint("Vibration triggered");
    try {
      Vibration.vibrate(duration: 1000); // 1 second vibration
    } catch (e) {
      debugPrint("Vibration failed: $e");
    }
  }
  
  Future<void> _triggerVoiceAlert(String message) async {
    debugPrint("Voice alert check - Enabled: $isVoiceAlertsEnabled, Speaking: $_isSpeaking");
    
    if (!isVoiceAlertsEnabled || _isSpeaking) {
      debugPrint("Voice alert skipped - Enabled: $isVoiceAlertsEnabled, Speaking: $_isSpeaking");
      return;
    }
    
    try {
      _isSpeaking = true;
      debugPrint("Speaking voice alert: $message");
      await _flutterTts.speak(message);
      debugPrint("Voice alert completed");
    } catch (e) {
      debugPrint("Voice alert failed: $e");
      _isSpeaking = false;
    }
  }
  
  void startDetection() {
    isRunning = true;
    notifyListeners();
    debugPrint('Detection service started');
  }
  
  void stopDetection() {
    isRunning = false;
    consecutiveDrowsyFrames = 0;
    consecutiveDistractionFrames = 0;
    
    // Clear advanced detection state
    earHistory.clear();
    headPoseHistory.clear();
    marHistory.clear();
    alertTriggeredFrame = 0;
    
    notifyListeners();
    debugPrint('Detection service stopped');
  }
  
  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
    debugPrint('Detection service disposed');
  }
}
