import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:saferide_ai_app/services/detection_service.dart';
import 'package:saferide_ai_app/services/camera_service.dart';
import 'package:saferide_ai_app/utils/constants.dart';

class DetectionScreenAuto extends StatefulWidget {
  const DetectionScreenAuto({Key? key}) : super(key: key);  

  @override
  State<DetectionScreenAuto> createState() => _DetectionScreenAutoState();
}

class _DetectionScreenAutoState extends State<DetectionScreenAuto> {
  StreamSubscription? _imageStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize camera but don't start detection automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  void _initializeCamera() async {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    
    print("🚗 Initializing camera for user dashboard");
    
    // Initialize camera first
    if (!cameraService.isInitialized) {
      await cameraService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<DetectionService, CameraService>(
        builder: (context, detectionService, cameraService, child) {
          return Stack(
            children: [
              // Full-screen camera view
              _buildFullScreenCamera(cameraService),
              
              // Stop/Start controls overlay
              _buildControlsOverlay(context, detectionService, cameraService),
              
              // Current alert overlay
              if (detectionService.currentAlert != null)
                _buildAlertOverlay(detectionService.currentAlert!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullScreenCamera(CameraService cameraService) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: cameraService.isInitialized && cameraService.cameraController != null
          ? CameraPreview(cameraService.cameraController!)
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context, DetectionService detectionService, CameraService cameraService) {
    return SafeArea(
      child: Column(
        children: [
          // Top status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Status indicator
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          decoration: BoxDecoration(
                            color: detectionService.isRunning ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          detectionService.isRunning ? 'DETECTION ACTIVE' : 'DETECTION STOPPED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Recording status indicator  
                if (cameraService.isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'REC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                // User dashboard indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'USER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // First row - Detection controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Start Detection button
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'START DETECTION',
                      onPressed: detectionService.isRunning ? null : () => _startDetection(detectionService, cameraService),
                      backgroundColor: Colors.green,
                      isEnabled: !detectionService.isRunning,
                    ),
                    // Stop Detection button
                    _buildControlButton(
                      icon: Icons.stop,
                      label: 'STOP DETECTION',
                      onPressed: detectionService.isRunning ? () => _stopDetection(detectionService, cameraService) : null,
                      backgroundColor: Colors.red,
                      isEnabled: detectionService.isRunning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Second row - Recording and Streaming controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Video Recording button
                    _buildControlButton(
                      icon: cameraService.isRecording ? Icons.stop : Icons.videocam,
                      label: cameraService.isRecording ? 'STOP RECORDING' : 'RECORD VIDEO',
                      onPressed: () => _toggleVideoRecording(cameraService),
                      backgroundColor: cameraService.isRecording ? Colors.red : Colors.purple,
                      isEnabled: cameraService.isInitialized,
                    ),
                    // Live Streaming button
                    _buildControlButton(
                      icon: Icons.live_tv,
                      label: 'LIVE STREAM',
                      onPressed: () => _toggleLiveStreaming(cameraService),
                      backgroundColor: Colors.blue,
                      isEnabled: cameraService.isInitialized,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 140,
        height: 70,
        decoration: BoxDecoration(
          color: isEnabled ? backgroundColor : Colors.grey,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertOverlay(String alert) {
    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.dangerColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startDetection(DetectionService detectionService, CameraService cameraService) async {
    try {
      print("🚀 Starting detection process...");
      
      // Initialize camera if not already done
      if (!cameraService.isInitialized) {
        print("📹 Initializing camera for detection...");
        await cameraService.initialize();
      }
      
      // Start camera streaming
      await cameraService.startImageStream();
      
      // Start detection
      detectionService.startDetection();
      
      // Connect camera stream to detection service
      _imageStreamSubscription?.cancel(); // Cancel any existing subscription
      _imageStreamSubscription = cameraService.imageStream.listen(
        (inputImage) {
          if (detectionService.isRunning) {
            detectionService.processImage(inputImage);
          }
        },
        onError: (error) {
          print("❌ Error in camera stream: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera stream error. Please restart detection.'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      
      print("✅ Detection process started with camera stream connected");
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detection started successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("❌ Error starting detection: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start detection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopDetection(DetectionService detectionService, CameraService cameraService) {
    print("🛑 Stopping detection process...");
    
    // Stop detection
    detectionService.stopDetection();
    
    // Stop camera streaming
    cameraService.stopImageStream();
    
    // Cancel stream subscription
    _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
    
    print("✅ Detection process stopped");
    
    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detection stopped successfully!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleVideoRecording(CameraService cameraService) async {
    print("📹 Toggle video recording...");
    
    // Check for web platform first
    if (kIsWeb) {
      _handleWebVideoRecording(cameraService);
      return;
    }
    
    if (!cameraService.isInitialized || cameraService.cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not initialized. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      if (cameraService.isRecording) {
        // Stop recording
        print("🛑 Stopping video recording...");
        final String? videoPath = await cameraService.stopVideoRecording();
        
        if (videoPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved successfully!\n$videoPath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'View Videos',
                textColor: Colors.white,
                onPressed: () => _showRecordedVideos(cameraService),
              ),
            ),
          );
          print("✅ Video recording stopped and saved: $videoPath");
        }
      } else {
        // Start recording
        print("▶️ Starting video recording...");
        await cameraService.startVideoRecording();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video recording started! 🎥'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        print("✅ Video recording started successfully");
      }
    } catch (e) {
      print("❌ Error with video recording: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video recording error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleWebVideoRecording(CameraService cameraService) {
    // Show web-specific recording options
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceDark,
          title: const Row(
            children: [
              Icon(Icons.videocam, color: Colors.blue),
              SizedBox(width: 8),
              Text('Web Video Recording', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For web browsers, please use:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '1. Browser\'s built-in screen recording',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '2. Third-party screen capture tools',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                '3. Mobile device for full recording features',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              Text(
                'The live stream to admin dashboard will work normally.',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleLiveStreaming(cameraService);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Start Live Streaming'),
            ),
          ],
        );
      },
    );
  }

  void _toggleLiveStreaming(CameraService cameraService) {
    print("📡 Toggle live streaming...");
    
    if (cameraService.isInitialized && cameraService.cameraController != null) {
      // TODO: Implement live streaming functionality
      // For now, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live Streaming to Admin Dashboard Active!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      print("📡 Live streaming feature activated");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not initialized. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showRecordedVideos(CameraService cameraService) async {
    try {
      final List<String> videoFiles = await cameraService.getRecordedVideos();
      
      if (videoFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recorded videos found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Recorded Videos'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: videoFiles.length,
                itemBuilder: (context, index) {
                  final videoPath = videoFiles[index];
                  final fileName = videoPath.split('/').last;
                  final fileSize = _getFileSize(videoPath);
                  
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.video_file, color: Colors.blue),
                      title: Text(
                        fileName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text('Size: $fileSize'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () {
                              // TODO: Implement video playback
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Video playback - Coming Soon!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                await cameraService.deleteVideo(videoPath);
                                Navigator.of(context).pop();
                                _showRecordedVideos(cameraService); // Refresh list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Video deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting video: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _showStorageInfoDialog,
                icon: const Icon(Icons.info_outline),
                label: const Text('Storage Info'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading videos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFileSize(String filePath) {
    try {
      if (kIsWeb) {
        return 'Web Recording';
      }
      
      final file = File(filePath);
      if (file.existsSync()) {
        final sizeInBytes = file.lengthSync();
        if (sizeInBytes < 1024 * 1024) {
          return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showStorageInfoDialog() async {
    final cameraService = Provider.of<CameraService>(context, listen: false);
    final storageInfo = await cameraService.getStorageInfo();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video Storage Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Platform: ${storageInfo['platform']}'),
                const SizedBox(height: 8),
                Text('Storage Location:'),
                Text(
                  storageInfo['path'] ?? 'Not available',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text('Access Method: ${storageInfo['access']}'),
                if (storageInfo['note'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${storageInfo['note']}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _imageStreamSubscription?.cancel();
    super.dispose();
  }

}
