import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:saferide_ai_app/services/detection_service.dart';
import 'package:saferide_ai_app/services/camera_service.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:saferide_ai_app/models/detection_model.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({Key? key}) : super(key: key);  

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically start detection when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutomaticDetection();
    });
  }

  void _startAutomaticDetection() async {
    final detectionService = Provider.of<DetectionService>(context, listen: false);
    final cameraService = Provider.of<CameraService>(context, listen: false);
    
    // Initialize camera first
    if (!cameraService.isInitialized) {
      await cameraService.initialize();
    }
    // Start camera streaming
    await cameraService.startImageStream();
    // Start detection automatically
    detectionService.startDetection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeRide AI - Auto Detection'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Consumer2<DetectionService, CameraService>(
        builder: (context, detectionService, cameraService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera Preview Card
                _buildCameraView(cameraService),
                const SizedBox(height: 20),
                
                // Status Card
                _buildStatusCard(detectionService),
                const SizedBox(height: 20),
                
                // Current Alert Display
                if (detectionService.currentAlert != null)
                  _buildCurrentAlert(detectionService.currentAlert!),
                
                const SizedBox(height: 20),
                
                // Automatic Detection Info
                _buildAutoDetectionInfo(),
                const SizedBox(height: 20),
                
                // Recent Detection History
                _buildDetectionHistory(detectionService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraView(CameraService cameraService) {
    return Card(
      elevation: 4,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: cameraService.isInitialized && cameraService.cameraController != null
              ? Stack(
                  children: [
                    CameraPreview(cameraService.cameraController!),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Camera not available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start detection to enable camera',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(DetectionService service) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: service.isRunning ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isRunning ? 'Detection Active' : 'Detection Stopped',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    service.isRunning 
                        ? 'Monitoring driver behavior in real-time'
                        : 'Tap Start to begin monitoring',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              service.isRunning ? Icons.visibility : Icons.visibility_off,
              color: service.isRunning ? Colors.green : Colors.red,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionHistory(DetectionService service) {

  Widget _buildDemoButtons(DetectionService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test All Detection Types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap any button below to test voice alerts and warnings:',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        // First Row - Drowsiness and Distraction
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('drowsiness'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.visibility_off, color: Colors.white),
                label: const Text(
                  'Test Drowsiness',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('distraction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.face, color: Colors.white),
                label: const Text(
                  'Test Distraction',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Second Row - Yawning and Motion Sickness
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('yawning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.sentiment_very_dissatisfied, color: Colors.white),
                label: const Text(
                  'Test Yawning',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('motion_sickness'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.sick, color: Colors.white),
                label: const Text(
                  'Test Motion Sickness',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Third Row - Phone Usage and Seatbelt
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('phone_usage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  'Test Phone Usage',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('no_seatbelt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.airline_seat_recline_extra, color: Colors.white),
                label: const Text(
                  'Test No Seatbelt',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Fourth Row - Erratic Movement and Passenger Disturbance  
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('erratic_movement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.warning, color: Colors.white),
                label: const Text(
                  'Test Erratic Movement',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('passenger_disturbance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.people, color: Colors.white),
                label: const Text(
                  'Test Passenger Alert',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Fifth Row - Smoking Detection (centered)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => service.triggerDemoAlert('smoking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.smoking_rooms, color: Colors.white),
                label: const Text(
                  'Test Smoking Detection',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Empty space to center the smoking button
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoDetectionInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_mode,
                  color: AppConstants.successColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Automatic Detection Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The system is continuously monitoring for:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetectionTypeRow(Icons.visibility_off, 'Drowsiness Detection', Colors.orange),
            _buildDetectionTypeRow(Icons.face, 'Distraction Monitoring', Colors.purple),
            _buildDetectionTypeRow(Icons.sentiment_very_dissatisfied, 'Yawning Detection', Colors.amber),
            _buildDetectionTypeRow(Icons.sick, 'Motion Sickness Detection', Colors.teal),
            _buildDetectionTypeRow(Icons.warning, 'Erratic Movement Detection', Colors.deepOrange),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🎯 No buttons needed - detection runs automatically!\n🔊 Voice alerts enabled for safety warnings\n📳 Vibration feedback for immediate attention',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionTypeRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentAlert(String alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.dangerColor.withOpacity(0.1),
        border: Border.all(color: AppConstants.dangerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppConstants.dangerColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert,
              style: TextStyle(
                color: AppConstants.dangerColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionHistory(DetectionService service) {
    final history = service.detectionHistory.recentDetections;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Detections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Center(
                child: Text(
                  'No recent detections',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...history.take(5).map((detection) => _buildHistoryItem(detection, service)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(DetectionResult detection, DetectionService service) {
    final timeStr = '${detection.timestamp.hour.toString().padLeft(2, '0')}:${detection.timestamp.minute.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getDetectionColor(detection.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getDetectionLabel(detection.type)),
                Text(
                  service.getVoiceMessageForDetection(detection.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getDetectionColor(DetectionType type) {
    switch (type) {
      case DetectionType.drowsiness:
        return AppConstants.dangerColor;
      case DetectionType.distraction:
        return AppConstants.warningColor;
      case DetectionType.yawning:
        return Colors.orange;
      case DetectionType.motionSickness:
        return AppConstants.primaryColor;
      case DetectionType.phoneUsage:
        return Colors.purple;
      case DetectionType.noSeatbelt:
        return Colors.red;
      case DetectionType.erraticMovement:
        return Colors.deepOrange;
      case DetectionType.passengerDisturbance:
        return Colors.brown;
      case DetectionType.smokingDetection:
        return Colors.grey;
    }
  }

  String _getDetectionLabel(DetectionType type) {
    switch (type) {
      case DetectionType.drowsiness:
        return 'Drowsiness Detected';
      case DetectionType.distraction:
        return 'Driver Distracted';
      case DetectionType.yawning:
        return 'Yawning Detected';
      case DetectionType.motionSickness:
        return 'Motion Sickness';
      case DetectionType.phoneUsage:
        return 'Phone Usage';
      case DetectionType.noSeatbelt:
        return 'No Seatbelt';
      case DetectionType.erraticMovement:
        return 'Erratic Movement';
      case DetectionType.passengerDisturbance:
        return 'Passenger Disturbance';
      case DetectionType.smokingDetection:
        return 'Smoking Detected';
    }
  }

  Widget _buildStatRow(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: count > 0 ? AppConstants.warningColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: count > 0 ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStatistics(DetectionService service) {
    final stats = service.detectionStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Detection Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => service.resetStats(),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatRow('Drowsiness', stats.drowsinessDetections, Icons.visibility_off),
        _buildStatRow('Distraction', stats.distractionDetections, Icons.face),
        _buildStatRow('Yawning', stats.yawningDetections, Icons.sentiment_very_dissatisfied),
        _buildStatRow('Motion Sickness', stats.motionSicknessDetections, Icons.sick),
        _buildStatRow('Phone Usage', stats.phoneUsageDetections, Icons.phone),
        _buildStatRow('No Seatbelt', stats.noSeatbeltDetections, Icons.airline_seat_recline_extra),
        _buildStatRow('Erratic Movement', stats.erraticMovementDetections, Icons.warning),
        _buildStatRow('Passenger Disturbance', stats.passengerDisturbanceDetections, Icons.people),
        _buildStatRow('Smoking Detection', stats.smokingDetections, Icons.smoking_rooms),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Detections:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${stats.getTotalDetections()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detection Settings & Statistics'),
        content: Consumer<DetectionService>(
          builder: (context, service, child) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Detection Statistics Section
                  _buildDialogStatistics(service),
                  const Divider(height: 32),
                  
                  // Settings Section
                  const Text(
                    'Detection Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Drowsiness Detection'),
                    value: service.isDrowsinessDetectionEnabled,
                    onChanged: (value) {
                      service.isDrowsinessDetectionEnabled = value;
                      service.saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Distraction Detection'),
                    value: service.isDistractionDetectionEnabled,
                    onChanged: (value) {
                      service.isDistractionDetectionEnabled = value;
                      service.saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Yawning Detection'),
                    value: service.isYawningDetectionEnabled,
                    onChanged: (value) {
                      service.isYawningDetectionEnabled = value;
                      service.saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Motion Sickness Detection'),
                    value: service.isMotionSicknessDetectionEnabled,
                    onChanged: (value) {
                      service.isMotionSicknessDetectionEnabled = value;
                      service.saveSettings();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Voice Alerts'),
                    value: service.isVoiceAlertsEnabled,
                    onChanged: (value) {
                      service.isVoiceAlertsEnabled = value;
                      service.saveSettings();
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
