import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:saferide_ai_app/models/detection_model.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebDetectionService extends ChangeNotifier {
  // Simulation timer for web demo
  Timer? _simulationTimer;
  
  // Detection state
  DetectionStats _currentStats = DetectionStats();
  DetectionResult? _lastResult;
  
  // Alert system
  int _alertCooldownSeconds = 5;
  DateTime? _lastAlertTime;
  
  // Settings
  double _earThreshold = DetectionConstants.defaultEarThreshold;
  double _marThreshold = DetectionConstants.defaultMarThreshold;
  double _headPoseThreshold = DetectionConstants.defaultHeadPoseThreshold;
  
  // Getters
  DetectionStats get currentStats => _currentStats;
  DetectionResult? get lastResult => _lastResult;
  bool get isSimulating => _simulationTimer?.isActive ?? false;
  
  Future<void> initialize() async {
    await _loadSettings();
    _startSimulation();
  }
  
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
  
  void _startSimulation() {
    // For web demo, we'll simulate detection events
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateDetection();
    });
  }
  
  void _simulateDetection() {
    final random = math.Random();
    
    // Simulate random detection events (rare)
    if (random.nextDouble() < 0.1) { // 10% chance
      DetectionType type;
      String message;
      
      int eventType = random.nextInt(3);
      switch (eventType) {
        case 0:
          type = DetectionType.drowsiness;
          message = 'Drowsiness detected (simulated)';
          _currentStats.drowsinessCount++;
          break;
        case 1:
          type = DetectionType.distraction;
          message = 'Distraction detected (simulated)';
          _currentStats.distractionCount++;
          break;
        case 2:
          type = DetectionType.fatigue;
          message = 'Fatigue detected (simulated)';
          _currentStats.fatigueCount++;
          break;
        default:
          return;
      }
      
      _currentStats.totalAlerts++;
      _currentStats.sessionDurationMinutes = 
          DateTime.now().difference(_currentStats.sessionStartTime).inMinutes;
      
      _lastResult = DetectionResult(
        type: type,
        confidence: 0.8 + random.nextDouble() * 0.2,
        message: message,
        timestamp: DateTime.now(),
      );
      
      _triggerAlert(type, message);
      notifyListeners();
    } else {
      // Normal state
      _lastResult = DetectionResult(
        type: DetectionType.normal,
        confidence: 0.9,
        message: 'Normal driving state (simulated)',
        timestamp: DateTime.now(),
      );
      notifyListeners();
    }
  }
  
  void _triggerAlert(DetectionType type, String message) {
    if (_shouldTriggerAlert()) {
      _lastAlertTime = DateTime.now();
      
      // For web, we can use HTML5 speech synthesis
      _speakAlert(message);
      
      // Visual alert (you could add more visual feedback here)
      debugPrint('ALERT: $message');
    }
  }
  
  void _speakAlert(String message) {
    try {
      final utterance = html.SpeechSynthesisUtterance(message);
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
      utterance.volume = 0.8;
      html.window.speechSynthesis?.speak(utterance);
    } catch (e) {
      debugPrint('Speech synthesis not available: $e');
    }
  }
  
  bool _shouldTriggerAlert() {
    if (_lastAlertTime == null) return true;
    
    final timeSinceLastAlert = DateTime.now().difference(_lastAlertTime!);
    return timeSinceLastAlert.inSeconds >= _alertCooldownSeconds;
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _earThreshold = prefs.getDouble(PreferenceKeys.earThreshold) ?? 
          DetectionConstants.defaultEarThreshold;
      _marThreshold = prefs.getDouble(PreferenceKeys.marThreshold) ?? 
          DetectionConstants.defaultMarThreshold;
      _headPoseThreshold = prefs.getDouble(PreferenceKeys.headPoseThreshold) ?? 
          DetectionConstants.defaultHeadPoseThreshold;
      _alertCooldownSeconds = prefs.getInt(PreferenceKeys.alertCooldownSeconds) ?? 5;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }
  
  Future<void> updateSettings({
    double? earThreshold,
    double? marThreshold,
    double? headPoseThreshold,
    int? alertCooldownSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (earThreshold != null) {
        _earThreshold = earThreshold;
        await prefs.setDouble(PreferenceKeys.earThreshold, earThreshold);
      }
      
      if (marThreshold != null) {
        _marThreshold = marThreshold;
        await prefs.setDouble(PreferenceKeys.marThreshold, marThreshold);
      }
      
      if (headPoseThreshold != null) {
        _headPoseThreshold = headPoseThreshold;
        await prefs.setDouble(PreferenceKeys.headPoseThreshold, headPoseThreshold);
      }
      
      if (alertCooldownSeconds != null) {
        _alertCooldownSeconds = alertCooldownSeconds;
        await prefs.setInt(PreferenceKeys.alertCooldownSeconds, alertCooldownSeconds);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
  }
  
  void resetStats() {
    _currentStats = DetectionStats();
    notifyListeners();
  }
  
  // Getters for settings
  double get earThreshold => _earThreshold;
  double get marThreshold => _marThreshold;
  double get headPoseThreshold => _headPoseThreshold;
  int get alertCooldownSeconds => _alertCooldownSeconds;
}
