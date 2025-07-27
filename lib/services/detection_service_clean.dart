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
  String? currentAlert;
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
      await _flutterTts.setSpeechRate(0.8);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
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
      final faces = await _faceDetector.processImage(inputImage);
      
      // Debug: Log face detection results occasionally
      if (DateTime.now().millisecondsSinceEpoch % 1000 < 100) {
        debugPrint('Face detection: ${faces.length} faces detected');
        if (faces.isNotEmpty) {
          final face = faces.first;
          debugPrint('Face bounds: ${face.boundingBox}');
          debugPrint('Left eye open: ${face.leftEyeOpenProbability}');
          debugPrint('Right eye open: ${face.rightEyeOpenProbability}');
          debugPrint('Head angles - X: ${face.headEulerAngleX}, Y: ${face.headEulerAngleY}');
        }
      }
      
      // Test alert every 15 seconds to verify voice system
      final now = DateTime.now();
      if (lastDrowsinessAlert == null || 
          now.difference(lastDrowsinessAlert!).inSeconds > 15) {
        _showAlert("Test alert: Detection system is working!");
        lastDrowsinessAlert = now;
        return;
      }
      
      if (faces.isEmpty) {
        consecutiveDrowsyFrames = 0;
        consecutiveDistractionFrames = 0;
        return;
      }
      
      // For simplicity, focus on the first detected face
      final face = faces.first;
      
      // Simple drowsiness detection
      if (isDrowsinessDetectionEnabled) {
        final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
        final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2.0;
        
        debugPrint('Drowsiness check - Eye openness: ${avgEyeOpen.toStringAsFixed(2)}, Threshold: ${AppConstants.eyeClosureThreshold}');
        
        if (avgEyeOpen < AppConstants.eyeClosureThreshold) {
          consecutiveDrowsyFrames++;
          debugPrint('Drowsy frame: $consecutiveDrowsyFrames/${AppConstants.drowsinessFrameThreshold}');
          
          if (consecutiveDrowsyFrames >= AppConstants.drowsinessFrameThreshold) {
            final now = DateTime.now();
            if (lastDrowsinessAlert == null || 
                now.difference(lastDrowsinessAlert!).inMilliseconds > AppConstants.drowsinessAlertCooldown) {
              
              _showAlert("Drowsiness detected! Driver appears to be sleeping!");
              
              final detection = DetectionResult(
                type: DetectionType.drowsiness,
                confidence: 1.0 - avgEyeOpen,
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.drowsiness);
              lastDrowsinessAlert = now;
              consecutiveDrowsyFrames = 0;
            }
          }
        } else {
          consecutiveDrowsyFrames = 0;
        }
      }
      
      // Simple distraction detection
      if (isDistractionDetectionEnabled) {
        if (face.headEulerAngleY != null) {
          final yaw = face.headEulerAngleY!.abs();
          debugPrint('Distraction check - Head yaw: ${yaw.toStringAsFixed(1)}°, Threshold: ${AppConstants.headPoseThreshold}°');
          
          if (yaw > AppConstants.headPoseThreshold) {
            consecutiveDistractionFrames++;
            debugPrint('Distraction frame: $consecutiveDistractionFrames/${AppConstants.distractionFrameThreshold}');
            
            if (consecutiveDistractionFrames >= AppConstants.distractionFrameThreshold) {
              final now = DateTime.now();
              if (lastDistractionAlert == null || 
                  now.difference(lastDistractionAlert!).inMilliseconds > AppConstants.distractionAlertCooldown) {
                
                _showAlert("Driver distracted! Please focus on the road!");
                
                final detection = DetectionResult(
                  type: DetectionType.distraction,
                  confidence: yaw / 90.0,
                  timestamp: now,
                );
                
                _detectionHistory.addDetection(detection);
                _detectionStats.incrementDetection(DetectionType.distraction);
                lastDistractionAlert = now;
                consecutiveDistractionFrames = 0;
              }
            }
          } else {
            consecutiveDistractionFrames = 0;
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }
  
  void _showAlert(String message) {
    debugPrint("ALERT: $message");
    
    currentAlert = message;
    
    _showVisualAlert(message);
    _triggerVoiceAlert(message);
    _triggerVibration();
    
    notifyListeners();
    
    Timer(Duration(seconds: 5), () {
      currentAlert = null;
      notifyListeners();
    });
  }
  
  void _showVisualAlert(String message) {
    debugPrint("Visual alert: $message");
  }
  
  void _triggerVibration() {
    debugPrint("Vibration triggered");
    try {
      Vibration.vibrate(duration: 1000);
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
    
    notifyListeners();
    debugPrint('Detection service stopped');
  }
  
  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
}
