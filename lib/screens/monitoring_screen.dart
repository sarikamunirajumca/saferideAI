import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:saferide_ai_app/screens/settings_screen.dart';
import 'package:saferide_ai_app/screens/installation_guide_screen.dart';
import 'package:saferide_ai_app/services/camera_service.dart';
import 'package:saferide_ai_app/services/detection_service.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({Key? key}) : super(key: key);

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> with WidgetsBindingObserver {
  bool _isMonitoring = false;
  bool _isWaitingToStart = false;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  StreamSubscription<InputImage>? _imageStreamSubscription;
  
  // Video recording variables
  bool _isRecording = false;
  String? _currentVideoPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    await cameraService.initialize();
  }
  
  void _startMonitoring() {
    if (_isMonitoring || _isWaitingToStart) return;
    
    // If startup delay is 0, start immediately
    if (AppConstants.startupDelay == 0) {
      _actuallyStartMonitoring();
      return;
    }
    
    setState(() {
      _isWaitingToStart = true;
      _countdownSeconds = (AppConstants.startupDelay / 1000).round(); // Convert ms to seconds
    });
    
    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });
      
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _actuallyStartMonitoring();
      }
    });
  }
  
  void _actuallyStartMonitoring() {
    setState(() {
      _isWaitingToStart = false;
      _isMonitoring = true;
    });
    
    final cameraService = Provider.of<CameraService>(context, listen: false);
    final detectionService = Provider.of<DetectionService>(context, listen: false);
    
    // Start the detection service first
    detectionService.startDetection();
    
    // Subscribe to image stream BEFORE starting camera
    _imageStreamSubscription = cameraService.imageStream.listen((inputImage) {
      debugPrint('📸 Image received by monitoring screen, passing to detection service');
      detectionService.processImage(inputImage);
    });
    
    // Start the camera AFTER subscription is ready
    cameraService.startImageStream();
    
    // Keep screen on while monitoring
    WakelockPlus.enable();
  }
  
  void _stopMonitoring() {
    if (!_isMonitoring && !_isWaitingToStart) return;
    
    // Cancel countdown timer if running
    _countdownTimer?.cancel();
    _countdownTimer = null;
    
    setState(() {
      _isWaitingToStart = false;
      _isMonitoring = false;
      _countdownSeconds = 0;
    });

    final cameraService = Provider.of<CameraService>(context, listen: false);
    final detectionService = Provider.of<DetectionService>(context, listen: false);
    
    // Stop video recording if active
    if (_isRecording) {
      _stopVideoRecording();
    }
    
    // Stop the camera
    cameraService.stopImageStream();
    
    // Stop the detection service
    detectionService.stopDetection();
    
    // Allow screen to turn off
    WakelockPlus.disable();
    
    // Unsubscribe from image stream
    _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
  }
  
  Future<void> _startVideoRecording() async {
    if (_isRecording) return;
    
    try {
      final cameraService = Provider.of<CameraService>(context, listen: false);
      
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = path.join(directory.path, 'saferide_recording_$timestamp.mp4');
      
      await cameraService.cameraController?.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _currentVideoPath = videoPath;
        _recordingStartTime = DateTime.now();
      });
      
      // Start timer to update recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording && mounted) {
          setState(() {}); // Update UI to show new duration
        }
      });
      
      // Show recording started message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video recording started'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;
    
    try {
      final cameraService = Provider.of<CameraService>(context, listen: false);
      final videoFile = await cameraService.cameraController?.stopVideoRecording();
      
      // Stop the recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });
      
      // Show recording saved message
      if (mounted && videoFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video saved: ${videoFile.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // You can implement video viewer here later
                debugPrint('Video path: ${videoFile.path}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      
      // Stop the recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      
      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatRecordingDuration() {
    if (_recordingStartTime == null) return '';
    final duration = DateTime.now().difference(_recordingStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _stopMonitoring();
        break;
      case AppLifecycleState.resumed:
        // Don't automatically restart, let the user decide
        break;
      default:
        break;
    }
  }
  
  @override
  void dispose() {
    _stopMonitoring();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _imageStreamSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final cameraService = Provider.of<CameraService>(context);
    final detectionService = Provider.of<DetectionService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InstallationGuideScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Center(
              child: cameraService.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: CameraPreview(cameraService.cameraController!),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),
          
          // Alert Banner
          if (detectionService.currentAlert != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: AppConstants.dangerColor,
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      detectionService.currentAlert!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Status and controls
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: _isMonitoring 
                          ? AppConstants.successColor 
                          : _isWaitingToStart 
                              ? AppConstants.warningColor 
                              : Colors.grey,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      _isMonitoring 
                          ? 'Monitoring Active' 
                          : _isWaitingToStart 
                              ? 'Starting in ${_countdownSeconds}s...'
                              : 'Monitoring Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20.0),
                  
                  // Countdown display when waiting to start
                  if (_isWaitingToStart)
                    Column(
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 48.0,
                          color: AppConstants.warningColor,
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Monitoring will start in:',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '${(_countdownSeconds ~/ 60).toString().padLeft(2, '0')}:${(_countdownSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.warningColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'This delay ensures proper setup time',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                      ],
                    ),
                  
                  const SizedBox(height: 20.0),
                  
                  // Video recording controls
                  if (_isMonitoring) ...[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: _isRecording ? Colors.red : Colors.grey,
                          width: 2.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isRecording ? Icons.videocam : Icons.videocam_off,
                                color: _isRecording ? Colors.red : Colors.grey,
                                size: 24.0,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                _isRecording ? 'Recording Active' : 'Recording Inactive',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isRecording ? Colors.red : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (_isRecording) ...[
                            const SizedBox(height: 8.0),
                            Text(
                              _formatRecordingDuration(),
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12.0),
                          ElevatedButton.icon(
                            onPressed: _isRecording ? _stopVideoRecording : _startVideoRecording,
                            icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                            label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),
                  ],
                  
                  // Start/Stop button
                  ElevatedButton(
                    onPressed: cameraService.isInitialized
                        ? ((_isMonitoring || _isWaitingToStart) ? _stopMonitoring : _startMonitoring)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isMonitoring || _isWaitingToStart)
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 16.0,
                      ),
                    ),
                    child: Text(
                      (_isMonitoring || _isWaitingToStart) 
                          ? 'Stop Monitoring' 
                          : 'Start Monitoring',
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
