import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:saferide_ai_app/models/detection_model.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class DetectionService extends ChangeNotifier {
  // ML models
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: true,  // Required for eye/mouth detection
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate, // Changed to accurate for better detection
      minFaceSize: 0.05, // Smaller minimum for better detection range
    ),
  );
  
  // Detection state
  bool isRunning = false;
  bool _hasTriggeredTestAlert = false;
  String? currentAlert;
  int consecutiveDrowsyFrames = 0;
  int consecutiveDistractionFrames = 0;
  DateTime? lastDrowsinessAlert;
  DateTime? lastDistractionAlert;
  DateTime? lastYawningAlert;
  DateTime? lastMotionSicknessAlert;
  
  // Web demo mode for testing voice alerts
  Timer? _webDemoTimer;
  int _webDemoCounter = 0;
  
  // Face position tracking for improved distraction detection
  Rect? _lastFacePosition;
  List<Rect> _facePositionHistory = [];
  static const int _maxPositionHistory = 10;
  
  // Timing control variables
  DateTime? _lastImageProcessTime;
  DateTime? _alertDisplayStartTime;
  bool _isVoiceAlertInProgress = false;
  DateTime? lastSeatbeltAlert;
  DateTime? lastPhoneUsageAlert;
  DateTime? lastSmokingAlert;
  DateTime? lastErraticMovementAlert;
  
  // Detection settings - Enable more features by default for better functionality
  bool isDrowsinessDetectionEnabled = true;
  bool isDistractionDetectionEnabled = true;
  bool isSeatbeltDetectionEnabled = true;
  bool isYawningDetectionEnabled = true;
  bool isPassengerMonitoringEnabled = true;
  bool isMotionSicknessDetectionEnabled = true; // Enable by default
  bool isPhoneUsageDetectionEnabled = true; // Enable by default
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
      await _flutterTts.setSpeechRate(0.6); // Slower speech for clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.2); // Higher pitch for urgency
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isVoiceAlertInProgress = false;
        debugPrint('🎤 TTS completion handler called');
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isVoiceAlertInProgress = false;
        debugPrint('❌ TTS error: $msg');
      });
      
      debugPrint('✅ TTS initialized successfully with enhanced settings');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    isDrowsinessDetectionEnabled = prefs.getBool(PreferenceKeys.isDrowsinessDetectionEnabled) ?? true;
    isDistractionDetectionEnabled = prefs.getBool(PreferenceKeys.isDistractionDetectionEnabled) ?? true;
    isSeatbeltDetectionEnabled = prefs.getBool(PreferenceKeys.isSeatbeltDetectionEnabled) ?? true;
    isYawningDetectionEnabled = prefs.getBool(PreferenceKeys.isYawningDetectionEnabled) ?? true;
    isPassengerMonitoringEnabled = prefs.getBool(PreferenceKeys.isPassengerMonitoringEnabled) ?? true;
    isMotionSicknessDetectionEnabled = prefs.getBool(PreferenceKeys.isMotionSicknessDetectionEnabled) ?? true; // Enable by default
    isPhoneUsageDetectionEnabled = prefs.getBool(PreferenceKeys.isPhoneUsageDetectionEnabled) ?? true; // Enable by default
    isSmokingDetectionEnabled = prefs.getBool(PreferenceKeys.isSmokingDetectionEnabled) ?? false;
    isErraticMovementDetectionEnabled = prefs.getBool(PreferenceKeys.isErraticMovementDetectionEnabled) ?? true;
    isVoiceAlertsEnabled = prefs.getBool(PreferenceKeys.isVoiceAlertsEnabled) ?? true;
    
    debugPrint('🔧 Detection settings loaded:');
    debugPrint('  - Drowsiness: $isDrowsinessDetectionEnabled');
    debugPrint('  - Distraction: $isDistractionDetectionEnabled');
    debugPrint('  - Yawning: $isYawningDetectionEnabled');
    debugPrint('  - Motion Sickness: $isMotionSicknessDetectionEnabled');
    debugPrint('  - Phone Usage: $isPhoneUsageDetectionEnabled');
    debugPrint('  - Erratic Movement: $isErraticMovementDetectionEnabled');
    debugPrint('  - Voice Alerts: $isVoiceAlertsEnabled');
    
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
    if (!isRunning) {
      debugPrint('processImage called but detection not running');
      return;
    }
    
    // Implement processing delay to prevent overwhelming the system
    final now = DateTime.now();
    if (_lastImageProcessTime != null && 
        now.difference(_lastImageProcessTime!).inMilliseconds < AppConstants.imageProcessingDelay) {
      // Skip this frame if processing too frequently
      return;
    }
    _lastImageProcessTime = now;
    
    // Minimal logging to improve performance (every 10 seconds)
    if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
      debugPrint('🔍 Processing frames for detection... Running: $isRunning');
    }
    
    // Enable test alert and web demo mode for testing
    if (!_hasTriggeredTestAlert) {
      debugPrint('🚀 Triggering test alert...');
      _hasTriggeredTestAlert = true;
      _showAlert("Detection started! Voice alerts are working!");
      
      // Start web demo mode for voice alert testing
      if (kIsWeb) {
        _startWebDemoMode();
      }
      return;
    }
    
    // Web demo mode - simulate alerts for testing voice system
    if (kIsWeb) {
      return; // Skip face detection on web, let demo mode handle alerts
    }
    
    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      // Simplified face detection logging
      if (faces.isEmpty) {
        // Only log occasionally to avoid spam
        if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
          debugPrint('⚠️  No faces detected - check camera position, lighting, or face detector settings');
          debugPrint('   📊 Image info: ${inputImage.metadata?.size.width.toInt() ?? 'unknown'}x${inputImage.metadata?.size.height.toInt() ?? 'unknown'}');
          debugPrint('   🔧 Face detector settings: minFaceSize=${_faceDetector.options.minFaceSize}, mode=${_faceDetector.options.performanceMode}, classification=${_faceDetector.options.enableClassification}');
        }
        consecutiveDrowsyFrames = 0;
        consecutiveDistractionFrames = 0;
        return;
      }
      
      // Log successful detection with more details
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        final face = faces.first;
        debugPrint('✅ Face detected! Bounding box: ${face.boundingBox}');
        debugPrint('   📊 Image info: ${inputImage.metadata?.size.width.toInt()}x${inputImage.metadata?.size.height.toInt()}');
        debugPrint('   🔧 Face detector settings: minFaceSize=${_faceDetector.options.minFaceSize}, mode=${_faceDetector.options.performanceMode}, classification=${_faceDetector.options.enableClassification}');
      }
      
      // For simplicity, focus on the first detected face
      final face = faces.first;
      
      // Simple drowsiness detection
      if (isDrowsinessDetectionEnabled) {
        final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
        final avgEyeOpen = (leftEyeOpen + rightEyeOpen) / 2.0;
        
        // Reduce debug logging frequency for performance  
        if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
          debugPrint('👁️ Eyes: L=${leftEyeOpen.toStringAsFixed(2)}, R=${rightEyeOpen.toStringAsFixed(2)}, Avg=${avgEyeOpen.toStringAsFixed(2)}');
        }
        
        // Check if eyes are closed (below threshold)
        if (avgEyeOpen < AppConstants.eyeClosureThreshold) {
          consecutiveDrowsyFrames++;
          debugPrint('😴 Eyes closed detected! Frame ${consecutiveDrowsyFrames}/${AppConstants.drowsinessFrameThreshold}');
          
          if (consecutiveDrowsyFrames >= AppConstants.drowsinessFrameThreshold) {
            final now = DateTime.now();
            debugPrint('😴 Drowsiness threshold reached! Last alert: $lastDrowsinessAlert');
            
            if (lastDrowsinessAlert == null || 
                now.difference(lastDrowsinessAlert!).inMilliseconds > AppConstants.drowsinessAlertCooldown) {
              
              debugPrint('� DROWSINESS ALERT TRIGGERED! Consecutive frames: $consecutiveDrowsyFrames');
              _showAlert("WAKE UP! Driver appears to be falling asleep!");
              
              final detection = DetectionResult(
                type: DetectionType.drowsiness,
                confidence: 1.0 - avgEyeOpen,
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.drowsiness);
              lastDrowsinessAlert = now;
              consecutiveDrowsyFrames = 0;
            } else {
              final cooldownRemaining = AppConstants.drowsinessAlertCooldown - now.difference(lastDrowsinessAlert!).inMilliseconds;
              debugPrint('😴 Drowsiness detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        } else {
          if (consecutiveDrowsyFrames > 0) {
            debugPrint('👁️ Eyes opened - resetting drowsy frame count from $consecutiveDrowsyFrames to 0');
          }
          consecutiveDrowsyFrames = 0;
        }
      }
      
      // Enhanced distraction detection
      if (isDistractionDetectionEnabled) {
        bool isDistracted = false;
        double distractionConfidence = 0.0;
        
        // Method 1: Head pose angle detection
        if (face.headEulerAngleY != null) {
          final yaw = face.headEulerAngleY!.abs();
          
          // Reduce debug logging frequency for performance
          if (DateTime.now().millisecondsSinceEpoch % 4000 < 100) {
            debugPrint('🔄 Distraction check - Head yaw: ${yaw.toStringAsFixed(1)}°, Threshold: ${AppConstants.headPoseThreshold}°');
          }
          
          if (yaw > AppConstants.headPoseThreshold) {
            isDistracted = true;
            distractionConfidence = (yaw / 45.0).clamp(0.0, 1.0); // Normalize to 0-1
          }
        }
        
        // Method 2: Face position movement detection
        // Track face position history
        _facePositionHistory.add(face.boundingBox);
        if (_facePositionHistory.length > _maxPositionHistory) {
          _facePositionHistory.removeAt(0);
        }
        
        // Check for significant face position movement
        if (_facePositionHistory.length >= 5) {
          final firstPos = _facePositionHistory.first;
          final lastPos = _facePositionHistory.last;
          final firstCenter = Offset(
            firstPos.left + firstPos.width / 2,
            firstPos.top + firstPos.height / 2,
          );
          final lastCenter = Offset(
            lastPos.left + lastPos.width / 2,
            lastPos.top + lastPos.height / 2,
          );
          
          final movement = (firstCenter - lastCenter).distance;
          final movementThreshold = 50.0; // pixels
          
          // Reduce debug logging frequency for performance
          if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
            debugPrint('🔄 Face movement: ${movement.toStringAsFixed(1)}px, Threshold: ${movementThreshold}px');
          }
          
          if (movement > movementThreshold) {
            isDistracted = true;
            distractionConfidence = (movement / 100.0).clamp(0.0, 1.0); // Normalize to 0-1
          }
        }
        
        if (isDistracted) {
          consecutiveDistractionFrames++;
          
          if (consecutiveDistractionFrames >= AppConstants.distractionFrameThreshold) {
            final now = DateTime.now();
            debugPrint('🔄 Distraction threshold reached! Last alert: $lastDistractionAlert');
            
            if (lastDistractionAlert == null || 
                now.difference(lastDistractionAlert!).inMilliseconds > AppConstants.distractionAlertCooldown) {
              
              debugPrint('🔄 DISTRACTION ALERT TRIGGERED! Consecutive frames: $consecutiveDistractionFrames');
              _showAlert("🔄 Driver distracted! Please focus on the road!");
              
              final detection = DetectionResult(
                type: DetectionType.distraction,
                confidence: distractionConfidence,
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.distraction);
              lastDistractionAlert = now;
              consecutiveDistractionFrames = 0;
            } else {
              final cooldownRemaining = AppConstants.distractionAlertCooldown - now.difference(lastDistractionAlert!).inMilliseconds;
              debugPrint('🔄 Distraction detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        } else {
          consecutiveDistractionFrames = 0;
        }
      }
      
      // Enhanced yawning detection based on mouth opening
      if (isYawningDetectionEnabled) {
        // Use smilingProbability as a proxy for mouth openness (inverse relationship)
        final mouthOpen = face.smilingProbability != null ? (1.0 - face.smilingProbability!) : 0.0;
        
        // Reduce debug logging frequency for performance
        if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
          debugPrint('🥱 Yawning check - Mouth openness: ${mouthOpen.toStringAsFixed(2)}, Smiling prob: ${face.smilingProbability?.toStringAsFixed(2) ?? "null"}, Threshold: ${AppConstants.mouthAspectRatioThreshold}');
        }
        
        if (mouthOpen > AppConstants.mouthAspectRatioThreshold) {
          final now = DateTime.now();
          if (lastYawningAlert == null || 
              now.difference(lastYawningAlert!).inMilliseconds > AppConstants.yawningAlertCooldown) {
            
            debugPrint('🥱 YAWNING ALERT TRIGGERED! Mouth openness: ${mouthOpen.toStringAsFixed(2)}');
            _showAlert("Yawning detected! Driver may be getting tired!");
            
            final detection = DetectionResult(
              type: DetectionType.yawning,
              confidence: mouthOpen,
              timestamp: now,
            );
            
            _detectionHistory.addDetection(detection);
            _detectionStats.incrementDetection(DetectionType.yawning);
            lastYawningAlert = now;
          } else {
            final cooldownRemaining = AppConstants.yawningAlertCooldown - now.difference(lastYawningAlert!).inMilliseconds;
            debugPrint('🥱 Yawning detected but in cooldown (${cooldownRemaining}ms remaining)');
          }
        }
      }
      
      // Enhanced motion sickness detection based on excessive head movement
      if (isMotionSicknessDetectionEnabled) {
        if (face.headEulerAngleX != null && face.headEulerAngleY != null) {
          final totalHeadMovement = face.headEulerAngleX!.abs() + face.headEulerAngleY!.abs();
          
          // Reduce debug logging frequency for performance
          if (DateTime.now().millisecondsSinceEpoch % 3000 < 100) {
            debugPrint('🤢 Motion sickness check - X angle: ${face.headEulerAngleX!.toStringAsFixed(1)}°, Y angle: ${face.headEulerAngleY!.toStringAsFixed(1)}°, Total: ${totalHeadMovement.toStringAsFixed(1)}°, Threshold: ${AppConstants.motionSicknessThreshold * 10}°');
          }
          
          if (totalHeadMovement > AppConstants.motionSicknessThreshold * 10) {
            final now = DateTime.now();
            // Only trigger motion sickness if no yawning alert was recently triggered
            if ((lastMotionSicknessAlert == null || 
                now.difference(lastMotionSicknessAlert!).inMilliseconds > AppConstants.motionSicknessAlertCooldown) &&
                (lastYawningAlert == null || 
                now.difference(lastYawningAlert!).inMilliseconds > 2000)) { // 2 second gap from yawning
              
              debugPrint('🤢 MOTION SICKNESS ALERT TRIGGERED! Total movement: ${totalHeadMovement.toStringAsFixed(1)}°');
              _showAlert("Motion sickness detected! Driver appears unwell!");
              
              final detection = DetectionResult(
                type: DetectionType.motionSickness,
                confidence: (totalHeadMovement / 60.0).clamp(0.0, 1.0),
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.motionSickness);
              lastMotionSicknessAlert = now;
            } else {
              final cooldownRemaining = AppConstants.motionSicknessAlertCooldown - now.difference(lastMotionSicknessAlert!).inMilliseconds;
              debugPrint('🤢 Motion sickness detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        }
      }
      
      // Seatbelt detection (simulated based on face position and posture)
      if (isSeatbeltDetectionEnabled) {
        // Use face position and head angles to simulate seatbelt detection
        final faceArea = face.boundingBox.width * face.boundingBox.height;
        final faceY = face.boundingBox.top;
        
        // Simple heuristic: if face is too low in frame or face area is very large (too close),
        // it might indicate improper seating position (no seatbelt)
        if (faceY > 300 || faceArea > 50000) { // Adjusted thresholds
          final now = DateTime.now();
          if (lastSeatbeltAlert == null || 
              now.difference(lastSeatbeltAlert!).inMilliseconds > 30000) { // 30 second cooldown
            
            debugPrint('🔒 SEATBELT ALERT TRIGGERED! Face position: Y=${faceY.toStringAsFixed(1)}, Area=${faceArea.toStringAsFixed(1)}');
            _showAlert("Seatbelt not detected! Please fasten your seatbelt!");
            
            final detection = DetectionResult(
              type: DetectionType.noSeatbelt,
              confidence: 0.8,
              timestamp: now,
            );
            
            _detectionHistory.addDetection(detection);
            _detectionStats.incrementDetection(DetectionType.noSeatbelt);
            lastSeatbeltAlert = now;
          } else {
            final cooldownRemaining = 30000 - now.difference(lastSeatbeltAlert!).inMilliseconds;
            debugPrint('🔒 Seatbelt issue detected but in cooldown (${cooldownRemaining}ms remaining)');
          }
        }
      }
      
      // Phone usage detection (simulated based on face angles and position)
      if (isPhoneUsageDetectionEnabled) {
        // Use head angle and face position to detect phone usage patterns
        if (face.headEulerAngleX != null && face.headEulerAngleY != null) {
          final headTilt = face.headEulerAngleX!.abs();
          final headTurn = face.headEulerAngleY!.abs();
          
          // Phone usage pattern: head tilted down and slightly to one side
          if (headTilt > 20 && headTurn > 10 && headTilt < 60) {
            final now = DateTime.now();
            if (lastPhoneUsageAlert == null || 
                now.difference(lastPhoneUsageAlert!).inMilliseconds > 15000) { // 15 second cooldown
              
              debugPrint('📱 PHONE USAGE ALERT TRIGGERED! Head tilt: ${headTilt.toStringAsFixed(1)}°, turn: ${headTurn.toStringAsFixed(1)}°');
              _showAlert("Phone usage detected! Keep hands on wheel!");
              
              final detection = DetectionResult(
                type: DetectionType.phoneUsage,
                confidence: ((headTilt + headTurn) / 80.0).clamp(0.0, 1.0),
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.phoneUsage);
              lastPhoneUsageAlert = now;
            } else {
              final cooldownRemaining = 15000 - now.difference(lastPhoneUsageAlert!).inMilliseconds;
              debugPrint('📱 Phone usage detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        }
      }
      
      // Simple erratic movement detection
      if (isErraticMovementDetectionEnabled) {
        if (face.headEulerAngleX != null && face.headEulerAngleY != null) {
          final totalMovement = face.headEulerAngleX!.abs() + face.headEulerAngleY!.abs() + (face.headEulerAngleZ?.abs() ?? 0);
          
          // Log occasionally for debugging
          if (DateTime.now().millisecondsSinceEpoch % 4000 < 100) {
            debugPrint('Erratic movement check - Total movement: ${totalMovement.toStringAsFixed(1)}°');
          }
          
          if (totalMovement > 80.0) {
            final now = DateTime.now();
            if (lastErraticMovementAlert == null || 
                now.difference(lastErraticMovementAlert!).inMilliseconds > 3000) {
              
              debugPrint('🚨 ERRATIC MOVEMENT ALERT TRIGGERED! Total movement: ${totalMovement.toStringAsFixed(1)}°');
              _showAlert("Erratic movement detected! Driver behavior unusual!");
              
              final detection = DetectionResult(
                type: DetectionType.erraticMovement,
                confidence: (totalMovement / 120.0).clamp(0.0, 1.0),
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.erraticMovement);
              lastErraticMovementAlert = now;
            } else {
              final cooldownRemaining = 3000 - now.difference(lastErraticMovementAlert!).inMilliseconds;
              debugPrint('🚨 Erratic movement detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        }
      }
      
      // Smoking detection (simulated based on mouth and head patterns)
      if (isSmokingDetectionEnabled) {
        // Use mouth position and head angles to detect potential smoking
        if (face.headEulerAngleX != null && face.smilingProbability != null) {
          final headTilt = face.headEulerAngleX!;
          final mouthPattern = face.smilingProbability!;
          
          // Smoking pattern: slight head tilt back, specific mouth position
          if (headTilt < -5 && mouthPattern < 0.3) {
            final now = DateTime.now();
            if (lastSmokingAlert == null || 
                now.difference(lastSmokingAlert!).inMilliseconds > 20000) { // 20 second cooldown
              
              debugPrint('🚭 SMOKING ALERT TRIGGERED! Head tilt: ${headTilt.toStringAsFixed(1)}°, mouth: ${mouthPattern.toStringAsFixed(2)}');
              _showAlert("Smoking detected! Please avoid smoking while driving!");
              
              final detection = DetectionResult(
                type: DetectionType.smokingDetection,
                confidence: ((-headTilt + (1.0 - mouthPattern)) / 10.0).clamp(0.0, 1.0),
                timestamp: now,
              );
              
              _detectionHistory.addDetection(detection);
              _detectionStats.incrementDetection(DetectionType.smokingDetection);
              lastSmokingAlert = now;
            } else {
              final cooldownRemaining = 20000 - now.difference(lastSmokingAlert!).inMilliseconds;
              debugPrint('🚭 Smoking detected but in cooldown (${cooldownRemaining}ms remaining)');
            }
          }
        }
      }
      
      // Passenger disturbance detection (based on multiple faces)
      if (isPassengerMonitoringEnabled && faces.length > 1) {
        final now = DateTime.now();
        // Create a separate timestamp check for passenger alerts
        final passengerAlertTime = lastPhoneUsageAlert ?? DateTime(2000); // Use phone usage timestamp as proxy
        if (now.difference(passengerAlertTime).inMilliseconds > 25000) { // 25 second cooldown
          
          debugPrint('👥 PASSENGER DISTURBANCE ALERT TRIGGERED! Face count: ${faces.length}');
          _showAlert("Passenger disturbance detected! Multiple people in driver area!");
          
          final detection = DetectionResult(
            type: DetectionType.passengerDisturbance,
            confidence: (faces.length / 3.0).clamp(0.0, 1.0),
            timestamp: now,
          );
          
          _detectionHistory.addDetection(detection);
          _detectionStats.incrementDetection(DetectionType.passengerDisturbance);
          lastPhoneUsageAlert = now; // Reusing this timestamp for passenger alerts
        }
      }
      
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }
  
  void _showAlert(String message) {
    debugPrint("🚨 ALERT TRIGGERED: $message");
    
    // Only update visual alert if no alert is currently being displayed or this is higher priority
    if (currentAlert == null || _isHigherPriorityAlert(message, currentAlert!)) {
      currentAlert = message;
      _alertDisplayStartTime = DateTime.now();
      
      // Show visual alert immediately
      _showVisualAlert(message);
      
      // Notify listeners immediately to update UI
      notifyListeners();
      
      // Clear alert after specified duration
      Timer(Duration(milliseconds: AppConstants.alertDisplayDuration), () {
        if (currentAlert == message) { // Only clear if this is still the current alert
          currentAlert = null;
          _alertDisplayStartTime = null;
          notifyListeners();
          debugPrint("🔔 Alert cleared: $message");
        }
      });
    } else {
      debugPrint("🔕 Visual alert skipped - another alert is being displayed: $currentAlert");
    }
    
    // Always trigger vibration (can happen multiple times)
    Timer(Duration(milliseconds: AppConstants.vibrationDelay), () {
      _triggerVibration();
    });
    
    // Always trigger voice alert (with queueing logic in the voice method)
    Timer(Duration(milliseconds: AppConstants.voiceAlertDelay), () {
      _triggerVoiceAlert(message);
    });
  }
  
  // Helper method to determine alert priority (higher priority alerts can override lower ones)
  bool _isHigherPriorityAlert(String newAlert, String currentAlert) {
    // Define priority order (higher number = higher priority)
    const alertPriorities = {
      'WAKE UP': 5,
      'drowsiness': 5,
      'falling asleep': 5,
      'Yawning detected': 3,
      'getting tired': 3,
      'Motion sickness': 2,
      'unwell': 2,
      'Distraction': 4,
      'focus on the road': 4,
      'Phone usage': 3,
      'Seatbelt': 1,
      'Erratic movement': 2,
    };
    
    int newPriority = 0;
    int currentPriority = 0;
    
    // Find priority for new alert
    for (String key in alertPriorities.keys) {
      if (newAlert.toLowerCase().contains(key.toLowerCase())) {
        newPriority = alertPriorities[key]!;
        break;
      }
    }
    
    // Find priority for current alert
    for (String key in alertPriorities.keys) {
      if (currentAlert.toLowerCase().contains(key.toLowerCase())) {
        currentPriority = alertPriorities[key]!;
        break;
      }
    }
    
    return newPriority > currentPriority;
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
    debugPrint("🔊 Voice alert check - Enabled: $isVoiceAlertsEnabled, Speaking: $_isSpeaking, InProgress: $_isVoiceAlertInProgress");
    
    if (!isVoiceAlertsEnabled) {
      debugPrint("🔇 Voice alerts disabled, skipping TTS");
      return;
    }
    
    if (_isSpeaking || _isVoiceAlertInProgress) {
      debugPrint("🔇 Voice alert already in progress, skipping");
      return;
    }
    
    try {
      _isSpeaking = true;
      _isVoiceAlertInProgress = true;
      debugPrint("🎤 Starting voice alert: $message");
      
      // Stop any existing speech first
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Speak the alert message
      final result = await _flutterTts.speak(message);
      debugPrint("🎤 TTS speak result: $result");
      
      // Set a timeout to ensure flags are reset even if completion handler fails
      Timer(const Duration(seconds: 8), () {
        if (_isSpeaking || _isVoiceAlertInProgress) {
          debugPrint("🎤 TTS timeout - resetting flags");
          _isSpeaking = false;
          _isVoiceAlertInProgress = false;
        }
      });
      
      debugPrint("✅ Voice alert initiated successfully");
    } catch (e) {
      debugPrint("❌ Voice alert failed: $e");
      _isSpeaking = false;
      _isVoiceAlertInProgress = false;
    }
  }
  
  // Web demo mode to test voice alerts
  void _startWebDemoMode() {
    debugPrint("🌐 Starting web demo mode for voice alert testing");
    _webDemoTimer?.cancel();
    
    _webDemoTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!isRunning) {
        timer.cancel();
        return;
      }
      
      _webDemoCounter++;
      final messages = [
        "Demo alert: Testing drowsiness detection!",
        "Demo alert: Testing distraction warning!",
        "Demo alert: Testing yawning detection!",
        "Demo alert: Testing motion sickness alert!",
        "Demo alert: Phone usage detected!",
        "Demo alert: Seatbelt reminder!",
        "Demo alert: All voice systems working correctly!",
      ];
      
      final message = messages[_webDemoCounter % messages.length];
      debugPrint("🌐 Demo alert #$_webDemoCounter: $message");
      _showAlert(message);
      
      // Also update detection stats for demo
      final detectionTypes = [
        DetectionType.drowsiness,
        DetectionType.distraction,
        DetectionType.yawning,
        DetectionType.motionSickness,
        DetectionType.phoneUsage,
        DetectionType.noSeatbelt,
      ];
      
      final randomType = detectionTypes[_webDemoCounter % detectionTypes.length];
      final detection = DetectionResult(
        type: randomType,
        confidence: 0.8 + (_webDemoCounter % 3) * 0.1,
        timestamp: DateTime.now(),
      );
      
      _detectionHistory.addDetection(detection);
      _detectionStats.incrementDetection(randomType);
    });
  }
  
  void startDetection() {
    debugPrint('🟢 Detection service starting...');
    isRunning = true;
    _hasTriggeredTestAlert = false; // Reset test alert flag
    
    // Reset face position tracking
    _facePositionHistory.clear();
    _lastFacePosition = null;
    
    // Reset timing variables
    _lastImageProcessTime = null;
    _alertDisplayStartTime = null;
    _isVoiceAlertInProgress = false;
    
    // Reset all alert cooldown timers to allow immediate alerts
    lastDrowsinessAlert = null;
    lastDistractionAlert = null;
    lastYawningAlert = null;
    lastMotionSicknessAlert = null;
    lastSeatbeltAlert = null;
    lastPhoneUsageAlert = null;
    lastSmokingAlert = null;
    lastErraticMovementAlert = null;
    
    // Reset consecutive frame counters
    consecutiveDrowsyFrames = 0;
    consecutiveDistractionFrames = 0;
    
    notifyListeners();
    debugPrint('✅ Detection service started - Running: $isRunning, All cooldowns reset');
  }
  
  void stopDetection() {
    isRunning = false;
    _hasTriggeredTestAlert = false;
    consecutiveDrowsyFrames = 0;
    consecutiveDistractionFrames = 0;
    
    // Clean up web demo timer
    _webDemoTimer?.cancel();
    _webDemoTimer = null;
    _webDemoCounter = 0;
    
    // Reset face position tracking
    _facePositionHistory.clear();
    _lastFacePosition = null;
    
    // Reset timing variables
    _lastImageProcessTime = null;
    _alertDisplayStartTime = null;
    _isVoiceAlertInProgress = false;
    currentAlert = null;
    
    // Reset all alert cooldown timers
    lastDrowsinessAlert = null;
    lastDistractionAlert = null;
    lastYawningAlert = null;
    lastMotionSicknessAlert = null;
    lastSeatbeltAlert = null;
    lastPhoneUsageAlert = null;
    lastSmokingAlert = null;
    lastErraticMovementAlert = null;
    
    notifyListeners();
    debugPrint('🔴 Detection service stopped - All states reset');
  }
  
  void resetStats() {
    _detectionStats.drowsinessDetections = 0;
    _detectionStats.distractionDetections = 0;
    _detectionStats.noSeatbeltDetections = 0;
    _detectionStats.yawningDetections = 0;
    _detectionStats.passengerDisturbanceDetections = 0;
    _detectionStats.motionSicknessDetections = 0;
    _detectionStats.phoneUsageDetections = 0;
    _detectionStats.smokingDetections = 0;
    _detectionStats.erraticMovementDetections = 0;
    _detectionHistory.clearHistory();
    notifyListeners();
  }
  
  // Manual trigger method for testing alerts
  void triggerDemoAlert(String alertType) {
    if (!isRunning) return;
    
    switch (alertType.toLowerCase()) {
      case 'drowsiness':
        _triggerVoiceAlert("Demo alert: Testing drowsiness detection!");
        _detectionStats.drowsinessDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.drowsiness,
          confidence: 0.95,
          timestamp: DateTime.now(),
        ));
        break;
      case 'distraction':
        _triggerVoiceAlert("Demo alert: Testing distraction warning!");
        _detectionStats.distractionDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.distraction,
          confidence: 0.88,
          timestamp: DateTime.now(),
        ));
        break;
      case 'yawning':
        _triggerVoiceAlert("Demo alert: Testing yawning detection!");
        _detectionStats.yawningDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.yawning,
          confidence: 0.92,
          timestamp: DateTime.now(),
        ));
        break;
      case 'motion_sickness':
        _triggerVoiceAlert("Demo alert: Testing motion sickness detection!");
        _detectionStats.motionSicknessDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.motionSickness,
          confidence: 0.85,
          timestamp: DateTime.now(),
        ));
        break;
      case 'phone_usage':
        _triggerVoiceAlert("Demo alert: Phone usage detected!");
        _detectionStats.phoneUsageDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.phoneUsage,
          confidence: 0.90,
          timestamp: DateTime.now(),
        ));
        break;
      case 'no_seatbelt':
        _triggerVoiceAlert("Demo alert: Seatbelt not detected!");
        _detectionStats.noSeatbeltDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.noSeatbelt,
          confidence: 0.87,
          timestamp: DateTime.now(),
        ));
        break;
      case 'erratic_movement':
        _triggerVoiceAlert("Demo alert: Erratic movement detected!");
        _detectionStats.erraticMovementDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.erraticMovement,
          confidence: 0.83,
          timestamp: DateTime.now(),
        ));
        break;
      case 'passenger_disturbance':
        _triggerVoiceAlert("Demo alert: Passenger disturbance detected!");
        _detectionStats.passengerDisturbanceDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.passengerDisturbance,
          confidence: 0.91,
          timestamp: DateTime.now(),
        ));
        break;
      case 'smoking':
        _triggerVoiceAlert("Demo alert: Smoking detected in vehicle!");
        _detectionStats.smokingDetections++;
        _detectionHistory.addDetection(DetectionResult(
          type: DetectionType.smokingDetection,
          confidence: 0.89,
          timestamp: DateTime.now(),
        ));
        break;
    }
    notifyListeners();
  }

  // Helper method to get voice message for detection type
  String getVoiceMessageForDetection(DetectionType type) {
    switch (type) {
      case DetectionType.drowsiness:
        return "Drowsiness detected - please stay alert!";
      case DetectionType.distraction:
        return "Distraction warning - please focus on driving!";
      case DetectionType.yawning:
        return "Yawning detected - consider taking a break!";
      case DetectionType.motionSickness:
        return "Motion sickness detected - please pull over safely!";
      case DetectionType.phoneUsage:
        return "Phone usage detected - please put your phone away!";
      case DetectionType.noSeatbelt:
        return "Seatbelt not detected - please fasten your seatbelt!";
      case DetectionType.passengerDisturbance:
        return "Passenger disturbance detected!";
      case DetectionType.smokingDetection:
        return "Smoking detected - please avoid smoking while driving!";
      case DetectionType.erraticMovement:
        return "Erratic movement detected - please drive carefully!";
    }
  }
  
  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
}
