import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:saferide_ai_app/services/camera_service.dart';
import 'package:saferide_ai_app/services/detection_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _timestampTimer;
  String _currentTimestamp = '';

  @override
  void initState() {
    super.initState();
    _updateTimestamp();
    // Update timestamp every second for live feel
    _timestampTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimestamp();
    });
    
    // Initialize camera for admin monitoring when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAdminCamera();
    });
  }

  void _updateTimestamp() {
    setState(() {
      _currentTimestamp = DateTime.now().toString().substring(11, 19);
    });
  }

  void _initializeAdminCamera() async {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    
    print("🔒 Admin Dashboard: Initializing live streaming monitoring");
    
    // For web admin dashboard, don't initialize camera directly
    // Instead, check for available streams from devices
    if (kIsWeb) {
      print("🌐 Admin Dashboard: Web mode - Looking for device streams...");
      // Try to connect to device stream
      await _checkForDeviceStream();
    } else {
      // For mobile admin (secondary device monitoring)
      if (!cameraService.isInitialized) {
        await cameraService.initialize();
        print("✅ Admin Dashboard: Camera initialized for mobile admin monitoring");
      } else {
        print("✅ Admin Dashboard: Camera already initialized, ready for monitoring");
      }
    }
  }
  
  Future<void> _checkForDeviceStream() async {
    // Look for device stream on common network addresses
    // This would normally scan local network for device streams
    print("🔍 Admin Dashboard: Checking for active device streams...");
    // Implementation would go here to discover device streams
  }

  @override
  void dispose() {
    _timestampTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard - Live Streaming'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer2<CameraService, DetectionService>(
        builder: (context, cameraService, detectionService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin Welcome Card
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                
                // Live Camera Feed Card
                _buildLiveStreamCard(cameraService),
                const SizedBox(height: 20),
                
                // Detection Control Panel
                _buildDetectionControlPanel(detectionService),
                const SizedBox(height: 20),
                
                // System Status Card
                _buildSystemStatusCard(cameraService, detectionService),
                const SizedBox(height: 20),
                
                // Control Panel
                _buildControlPanel(cameraService),
                const SizedBox(height: 20),
                
                // Detection Statistics
                _buildDetectionStatsCard(detectionService),
                const SizedBox(height: 20),
                
                // Vehicle Info
                _buildVehicleInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Owner Dashboard - Live Vehicle Monitoring',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamCard(CameraService cameraService) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.videocam, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Live Camera Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.black,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: kIsWeb 
                  ? _buildWebLiveStream(cameraService)
                  : cameraService.isInitialized && cameraService.cameraController != null
                  ? Stack(
                      children: [
                        CameraPreview(cameraService.cameraController!),
                        // Live indicator
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE ADMIN VIEW',
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
                        // Resolution indicator
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HD 720p',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Real-time timestamp
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _currentTimestamp,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        // Admin monitoring badge
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'ADMIN MONITORING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
                            Icons.videocam_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Live Feed Disconnected',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click "Connect Live Feed" to start monitoring',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Admin Dashboard - Vehicle Monitoring System',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(CameraService cameraService, DetectionService detectionService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last Updated: ${_currentTimestamp}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Live Camera Feed',
              cameraService.isInitialized,
              Icons.videocam,
            ),
            _buildStatusRow(
              'Admin Connection',
              true,
              Icons.admin_panel_settings,
            ),
            _buildStatusRow(
              'Detection Service',
              detectionService.isRunning,
              Icons.visibility,
            ),
            _buildStatusRow(
              'Voice Alerts',
              detectionService.isVoiceAlertsEnabled,
              Icons.record_voice_over,
            ),
            _buildStatusRow(
              'Real-time Monitoring',
              cameraService.isInitialized && detectionService.isRunning,
              Icons.live_tv,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status ? 'ACTIVE' : 'INACTIVE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(CameraService cameraService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Live Feed Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cameraService.isInitialized ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cameraService.isInitialized ? 'CONNECTED' : 'DISCONNECTED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cameraService.isInitialized ? null : () async {
                      print("🔒 Admin: Starting live feed connection...");
                      await cameraService.initialize();
                      setState(() {});
                      print("✅ Admin: Live feed connected successfully");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'Connect Live Feed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cameraService.isInitialized ? () async {
                      print("🔒 Admin: Disconnecting live feed...");
                      await cameraService.dispose();
                      setState(() {});
                      print("✅ Admin: Live feed disconnected");
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text(
                      'Disconnect Feed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live feed shows real-time camera recording from the vehicle monitoring system',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Vehicle ID', 'SafeRide-001'),
            _buildInfoRow('Driver Mode', 'Detection Active'),
            _buildInfoRow('Location', 'Mobile Device'),
            _buildInfoRow('Stream Quality', 'HD 720p'),
            _buildInfoRow('Admin Session', 'Active'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionControlPanel(DetectionService detectionService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Detection Control Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: detectionService.isRunning,
                  onChanged: (value) {
                    if (value) {
                      // Start detection would need to be handled at the detection screen level
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Use the Detection Screen to start monitoring'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    } else {
                      detectionService.stopDetection();
                    }
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Detection Types Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildDetectionToggle(
                  'Drowsiness',
                  Icons.bedtime,
                  detectionService.isDrowsinessDetectionEnabled,
                  (value) {
                    detectionService.isDrowsinessDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Distraction',
                  Icons.visibility_off,
                  detectionService.isDistractionDetectionEnabled,
                  (value) {
                    detectionService.isDistractionDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Yawning',
                  Icons.sentiment_very_dissatisfied,
                  detectionService.isYawningDetectionEnabled,
                  (value) {
                    detectionService.isYawningDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Phone Usage',
                  Icons.phone_android,
                  detectionService.isPhoneUsageDetectionEnabled,
                  (value) {
                    detectionService.isPhoneUsageDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Seatbelt',
                  Icons.airline_seat_legroom_normal,
                  detectionService.isSeatbeltDetectionEnabled,
                  (value) {
                    detectionService.isSeatbeltDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Motion Sickness',
                  Icons.motion_photos_on,
                  detectionService.isMotionSicknessDetectionEnabled,
                  (value) {
                    detectionService.isMotionSicknessDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Smoking',
                  Icons.smoke_free,
                  detectionService.isSmokingDetectionEnabled,
                  (value) {
                    detectionService.isSmokingDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
                _buildDetectionToggle(
                  'Erratic Movement',
                  Icons.psychology,
                  detectionService.isErraticMovementDetectionEnabled,
                  (value) {
                    detectionService.isErraticMovementDetectionEnabled = value;
                    detectionService.saveSettings();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Voice Alerts Control
            Row(
              children: [
                const Icon(Icons.record_voice_over, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Voice Alerts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: detectionService.isVoiceAlertsEnabled,
                  onChanged: (value) {
                    detectionService.isVoiceAlertsEnabled = value;
                    detectionService.saveSettings();
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionToggle(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Colors.green : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: value ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: value ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionStatsCard(DetectionService detectionService) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Detection Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    detectionService.resetStats();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Statistics reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildStatCard('Drowsiness', detectionService.detectionStats.drowsinessDetections, Icons.bedtime, Colors.red),
                _buildStatCard('Distraction', detectionService.detectionStats.distractionDetections, Icons.visibility_off, Colors.orange),
                _buildStatCard('Yawning', detectionService.detectionStats.yawningDetections, Icons.sentiment_very_dissatisfied, Colors.amber),
                _buildStatCard('Phone Usage', detectionService.detectionStats.phoneUsageDetections, Icons.phone_android, Colors.purple),
                _buildStatCard('Seatbelt', detectionService.detectionStats.noSeatbeltDetections, Icons.airline_seat_legroom_normal, Colors.blue),
                _buildStatCard('Motion Sickness', detectionService.detectionStats.motionSicknessDetections, Icons.motion_photos_on, Colors.teal),
                _buildStatCard('Smoking', detectionService.detectionStats.smokingDetections, Icons.smoke_free, Colors.brown),
                _buildStatCard('Erratic Movement', detectionService.detectionStats.erraticMovementDetections, Icons.psychology, Colors.indigo),
                _buildStatCard('Passenger', detectionService.detectionStats.passengerDisturbanceDetections, Icons.people, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWebLiveStream(CameraService cameraService) {
    final cloudStreamInfo = cameraService.cloudStreamInfo;
    final isCloudStreaming = cloudStreamInfo['isStreaming'] ?? false;
    final cloudStreamingUrl = cameraService.cloudStreamingUrl;
    
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isCloudStreaming ? Colors.green.shade900.withOpacity(0.8) : Colors.blue.shade900.withOpacity(0.8),
                isCloudStreaming ? Colors.green.shade600.withOpacity(0.6) : Colors.blue.shade600.withOpacity(0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCloudStreaming ? Icons.cloud_done : Icons.devices,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                isCloudStreaming ? 'Cloud Stream Active' : 'Device Stream Connection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                isCloudStreaming 
                    ? 'Remote monitoring available worldwide'
                    : 'To view live stream from device:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCloudStreaming && cloudStreamingUrl != null) ...[
                      Text(
                        'Remote Access URL:',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cloudStreamingUrl,
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Session ID: ${cloudStreamInfo['sessionId'] ?? 'Generating...'}',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '✅ Share this URL with vehicle owner for remote monitoring',
                        style: TextStyle(color: Colors.green.shade300, fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '🌐 Works from anywhere with internet connection',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ] else ...[
                      Text(
                        '1. Open SafeRide app on mobile device',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '2. Start Detection/Monitoring',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '3. Cloud streaming will start automatically',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stream will appear here automatically',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Live streaming indicators for web
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCloudStreaming 
                  ? Colors.green.withOpacity(0.9)
                  : Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCloudStreaming ? Icons.cloud_done : Icons.wifi_find, 
                  color: Colors.white, 
                  size: 12
                ),
                SizedBox(width: 4),
                Text(
                  isCloudStreaming ? 'CLOUD STREAMING' : 'SEARCHING FOR DEVICE',
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
        // Connection type badge
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.web, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  isCloudStreaming ? 'REMOTE ACCESS' : 'WEB ADMIN DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Real-time timestamp
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentTimestamp,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


