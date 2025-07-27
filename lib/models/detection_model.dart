import 'package:saferide_ai_app/utils/constants.dart';

class DetectionResult {
  final DetectionType type;
  final double confidence;
  final DateTime timestamp;
  final String? imageFilePath; // Optional path to the image when detection occurred
  
  DetectionResult({
    required this.type,
    required this.confidence,
    required this.timestamp,
    this.imageFilePath,
  });
}

class DetectionStats {
  int drowsinessDetections = 0;
  int distractionDetections = 0;
  int noSeatbeltDetections = 0;
  int yawningDetections = 0;
  int passengerDisturbanceDetections = 0;
  int motionSicknessDetections = 0;
  int phoneUsageDetections = 0;        // New from car_ai
  int smokingDetections = 0;           // New from car_ai
  int erraticMovementDetections = 0;   // New from car_ai
  
  // Default constructor
  DetectionStats();
  
  void incrementDetection(DetectionType type) {
    switch (type) {
      case DetectionType.drowsiness:
        drowsinessDetections++;
        break;
      case DetectionType.distraction:
        distractionDetections++;
        break;
      case DetectionType.noSeatbelt:
        noSeatbeltDetections++;
        break;
      case DetectionType.yawning:
        yawningDetections++;
        break;
      case DetectionType.passengerDisturbance:
        passengerDisturbanceDetections++;
        break;
      case DetectionType.motionSickness:
        motionSicknessDetections++;
        break;
      case DetectionType.phoneUsage:
        phoneUsageDetections++;
        break;
      case DetectionType.smokingDetection:
        smokingDetections++;
        break;
      case DetectionType.erraticMovement:
        erraticMovementDetections++;
        break;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'drowsinessDetections': drowsinessDetections,
      'distractionDetections': distractionDetections,
      'noSeatbeltDetections': noSeatbeltDetections,
      'yawningDetections': yawningDetections,
      'passengerDisturbanceDetections': passengerDisturbanceDetections,
      'motionSicknessDetections': motionSicknessDetections,
      'phoneUsageDetections': phoneUsageDetections,
      'smokingDetections': smokingDetections,
      'erraticMovementDetections': erraticMovementDetections,
    };
  }
  
  factory DetectionStats.fromJson(Map<String, dynamic> json) {
    final stats = DetectionStats();
    stats.drowsinessDetections = json['drowsinessDetections'] ?? 0;
    stats.distractionDetections = json['distractionDetections'] ?? 0;
    stats.noSeatbeltDetections = json['noSeatbeltDetections'] ?? 0;
    stats.yawningDetections = json['yawningDetections'] ?? 0;
    stats.passengerDisturbanceDetections = json['passengerDisturbanceDetections'] ?? 0;
    stats.motionSicknessDetections = json['motionSicknessDetections'] ?? 0;
    stats.phoneUsageDetections = json['phoneUsageDetections'] ?? 0;
    stats.smokingDetections = json['smokingDetections'] ?? 0;
    stats.erraticMovementDetections = json['erraticMovementDetections'] ?? 0;
    return stats;
  }
}

class DetectionHistory {
  final List<DetectionResult> detections = [];
  
  void addDetection(DetectionResult detection) {
    detections.add(detection);
  }
  
  List<DetectionResult> getDetectionsOfType(DetectionType type) {
    return detections.where((detection) => detection.type == type).toList();
  }
  
  void clearHistory() {
    detections.clear();
  }
}
