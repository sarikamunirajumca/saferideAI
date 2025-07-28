import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
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
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  
  // Live streaming variables
  bool _isStreaming = false;
  String? _streamingUrl;
  bool _isRestartingServices = false;
  
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
    
    // Start live streaming automatically when monitoring starts
    _startLiveStreaming();
    
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
    
    // Stop live streaming
    _stopLiveStreaming();
    
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
      
      await cameraService.cameraController?.startVideoRecording();
      
      setState(() {
        _isRecording = true;
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
  
  // Live streaming methods
  Future<void> _startLiveStreaming() async {
    if (_isStreaming) return;
    
    try {
      final cameraService = Provider.of<CameraService>(context, listen: false);
      
      // Stop any existing streaming first
      await cameraService.stopLiveStreaming();
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to ensure cleanup
      
      final url = await cameraService.startLiveStreaming();
      
      if (url != null) {
        setState(() {
          _isStreaming = true;
          _streamingUrl = url;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.live_tv, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Live streaming started!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Access at: $url',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Copy',
                textColor: Colors.white,
                onPressed: () {
                  // Copy URL to clipboard
                  debugPrint('Copy URL to clipboard: $url');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('URL copied: $url'),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
        
        debugPrint('🌐 Live streaming started at: $url');
      } else {
        setState(() {
          _isStreaming = false;
          _streamingUrl = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to start live streaming'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isStreaming = false;
        _streamingUrl = null;
      });
      
      debugPrint('❌ Error starting live streaming: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Streaming error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _startLiveStreaming(),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _stopLiveStreaming() async {
    if (!_isStreaming) return;
    
    try {
      final cameraService = Provider.of<CameraService>(context, listen: false);
      await cameraService.stopLiveStreaming();
      
      setState(() {
        _isStreaming = false;
        _streamingUrl = null;
      });
      
      debugPrint('🔴 Live streaming stopped');
    } catch (e) {
      debugPrint('❌ Error stopping live streaming: $e');
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Don't stop monitoring completely, just pause some services
        debugPrint('📱 App went to background - preserving monitoring state');
        break;
      case AppLifecycleState.resumed:
        debugPrint('📱 App resumed - checking and restarting services');
        // Restart services if monitoring was active
        if (_isMonitoring) {
          _restartServicesIfNeeded();
        }
        break;
      default:
        break;
    }
  }
  
  Future<void> _restartServicesIfNeeded() async {
    if (_isRestartingServices) return; // Prevent multiple restart attempts
    
    setState(() {
      _isRestartingServices = true;
    });
    
    final cameraService = Provider.of<CameraService>(context, listen: false);
    final detectionService = Provider.of<DetectionService>(context, listen: false);
    
    try {
      debugPrint('🔄 Starting service restart...');
      
      // First, properly cleanup existing subscriptions and streams
      debugPrint('🔄 Cleaning up existing subscriptions...');
      _imageStreamSubscription?.cancel();
      _imageStreamSubscription = null;
      
      // Stop camera stream if running
      if (cameraService.isInitialized && 
          cameraService.cameraController != null && 
          cameraService.cameraController!.value.isStreamingImages) {
        debugPrint('🔄 Stopping existing camera stream...');
        await cameraService.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 500)); // Allow cleanup
      }
      
      // Stop streaming if active
      if (cameraService.isStreaming) {
        debugPrint('🔄 Stopping existing live streaming...');
        await cameraService.stopLiveStreaming();
        await Future.delayed(const Duration(milliseconds: 500)); // Allow cleanup
      }
      
      // Check and reinitialize camera if needed
      if (!cameraService.isInitialized) {
        debugPrint('🔄 Reinitializing camera service...');
        await cameraService.initialize();
        await Future.delayed(const Duration(milliseconds: 300)); // Allow initialization
      }
      
      // Restart detection service if not running
      if (!detectionService.isRunning) {
        debugPrint('🔄 Restarting detection service...');
        detectionService.startDetection();
      }
      
      // Now restart camera stream with fresh subscription
      if (cameraService.isInitialized) {
        debugPrint('🔄 Resetting camera image stream...');
        
        // Reset the image stream to create a fresh stream controller
        await cameraService.resetImageStream();
        
        debugPrint('🔄 Creating fresh image stream subscription...');
        
        // Create a new subscription to the image stream
        _imageStreamSubscription = cameraService.imageStream.listen(
          (inputImage) {
            debugPrint('📸 Image received by monitoring screen, passing to detection service');
            detectionService.processImage(inputImage);
          },
          onError: (error) {
            debugPrint('❌ Error in image stream subscription: $error');
          },
          onDone: () {
            debugPrint('🔚 Image stream subscription ended');
          },
        );
        
        debugPrint('🔄 Starting camera image stream...');
        await cameraService.startImageStream();
        await Future.delayed(const Duration(milliseconds: 500)); // Allow stream to start
      }
      
      // Restart live streaming if monitoring is active
      if (_isMonitoring) {
        debugPrint('🔄 Restarting live streaming...');
        await _startLiveStreaming();
      }
      
      setState(() {
        _isRestartingServices = false;
      });
      
      debugPrint('✅ All services restarted successfully');
      
      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'All monitoring services restored!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isRestartingServices = false;
      });
      
      debugPrint('❌ Error restarting services: $e');
      
      // Show user notification about the issue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Failed to restart services. Try manually.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _restartServicesIfNeeded();
              },
            ),
          ),
        );
      }
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
      backgroundColor: const Color(0xFF0A0E1A), // Dark blue background
      body: Stack(
        children: [
          // Full screen camera preview - fills entire screen including status bar
          Positioned.fill(
            child: cameraService.isInitialized
                ? CameraPreview(cameraService.cameraController!)
                : Container(
                    color: const Color(0xFF1E2A3A),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                            strokeWidth: 3.0,
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Initializing Camera...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          
          // Top overlay with app bar and status indicators - positioned at very top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top, // Status bar height
                left: 12.0,
                right: 12.0,
                bottom: 12.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App bar content
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 18.0,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const InstallationGuideScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4.0),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 18.0,
                          ),
                        ),
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
                  const SizedBox(height: 12.0),
                  // Status indicators row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: (_isMonitoring 
                              ? const Color(0xFF10B981) 
                              : _isWaitingToStart 
                                  ? const Color(0xFFF59E0B) 
                                  : const Color(0xFF6B7280)
                          ).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.0,
                              height: 6.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              _isMonitoring 
                                  ? 'ACTIVE' 
                                  : _isWaitingToStart 
                                      ? 'STARTING...'
                                      : 'INACTIVE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        children: [
                          // Live streaming indicator with URL display
                          if (_isStreaming || _isRestartingServices)
                            GestureDetector(
                              onTap: _isStreaming && _streamingUrl != null ? () {
                                // Show streaming URL dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E2A3A),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.live_tv, color: Color(0xFF3B82F6)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Live Stream URL',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Share this URL to view the live stream:',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A0E1A),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF3B82F6)),
                                          ),
                                          child: Text(
                                            _streamingUrl!,
                                            style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontFamily: 'monospace',
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          '• Open this URL in any web browser\n• Make sure you\'re on the same WiFi network\n• Works on phones, tablets, or computers',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          debugPrint('Copy URL to clipboard: $_streamingUrl');
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('URL copied: $_streamingUrl'),
                                              backgroundColor: const Color(0xFF10B981),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                        ),
                                        child: const Text(
                                          'Copy URL',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                margin: const EdgeInsets.only(right: 8.0),
                                decoration: BoxDecoration(
                                  color: (_isRestartingServices 
                                      ? const Color(0xFFF59E0B) 
                                      : const Color(0xFF3B82F6)
                                  ).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6.0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6.0,
                                      height: 6.0,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(3.0),
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      _isRestartingServices ? 'RESTARTING' : 'LIVE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),                          // Recording indicator
                          if (_isRecording)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6.0,
                                    height: 6.0,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    'REC ${_formatRecordingDuration()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Alert Banner - positioned below the top overlay
          if (detectionService.currentAlert != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120.0, // Status bar + overlay height
              left: 12.0,
              right: 12.0,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 15.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SAFETY ALERT',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            detectionService.currentAlert!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bottom overlay with controls - only show countdown when waiting to start
          if (_isWaitingToStart)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Countdown display when waiting to start
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          margin: const EdgeInsets.only(bottom: 20.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2A3A).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: const Color(0xFFF59E0B),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 15.0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  size: 32.0,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              const Text(
                                'Monitoring will start in:',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                '${(_countdownSeconds ~/ 60).toString().padLeft(2, '0')}:${(_countdownSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 36.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                'This delay ensures proper setup time',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.white.withOpacity(0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Floating start button when monitoring is not active and not waiting to start
          if (!_isMonitoring && !_isWaitingToStart)
            Positioned(
              bottom: 30.0,
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.0),
                    onTap: cameraService.isInitialized ? _startMonitoring : null,
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: const Icon(
                        Icons.play_circle_outlined,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Floating stop button when monitoring is active - positioned above recording button
          if (_isMonitoring && !_isWaitingToStart)
            Positioned(
              bottom: 100.0, // Above the recording button
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.0),
                    onTap: _stopMonitoring,
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: const Icon(
                        Icons.stop_circle_outlined,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Floating recording button when monitoring is active
          if (_isMonitoring && !_isWaitingToStart)
            Positioned(
              bottom: 30.0,
              right: 20.0,
              child: Container(
                decoration: BoxDecoration(
                  color: _isRecording 
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.0),
                    onTap: _isRecording ? _stopVideoRecording : _startVideoRecording,
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Floating restart streaming button - positioned to the left of record button when streaming is not active during monitoring
          if (_isMonitoring && !_isWaitingToStart && !_isStreaming && !_isRestartingServices)
            Positioned(
              bottom: 30.0,
              right: 90.0, // To the left of the recording button
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28.0),
                    onTap: () {
                      _restartServicesIfNeeded();
                    },
                    child: Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                      child: const Icon(
                        Icons.live_tv,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
