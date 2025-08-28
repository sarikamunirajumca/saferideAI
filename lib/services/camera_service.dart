import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import '../services/streaming_service.dart';
import '../services/cloud_streaming_service.dart';

class CameraService extends ChangeNotifier {
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  bool isInitialized = false;
  bool isProcessing = false;
  StreamController<InputImage>? _imageStreamController;
  final StreamingService _streamingService = StreamingService();
  final CloudStreamingService _cloudStreamingService = CloudStreamingService();
  
  // Video recording properties
  bool isRecording = false;
  String? currentVideoPath;
  XFile? lastRecordedVideo;
  
  // Frame skipping variables for performance optimization
  int _frameCount = 0;
  static const int _frameSkipCount = 2; // Process every 3rd frame for detection
  DateTime? _lastFrameProcessTime;
  static const int _minFrameInterval = 300; // Minimum 300ms between detection frames
  
  Stream<InputImage> get imageStream {
    // Create a new stream controller if one doesn't exist or is closed
    if (_imageStreamController == null || _imageStreamController!.isClosed) {
      _imageStreamController = StreamController<InputImage>.broadcast();
    }
    return _imageStreamController!.stream;
  }
  
  Future<void> initialize() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        if (kIsWeb) {
          debugPrint('🌐 Web platform: Camera access may require user permission');
        }
        return;
      }
      
      // Select the front-facing camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // Increased to medium for better face detection
        enableAudio: true, // Enable audio for video recording
        imageFormatGroup: ImageFormatGroup.nv21, // Use NV21 for better ML Kit compatibility
      );
      
      await cameraController!.initialize();
      
      // Additional camera settings for optimal performance and color
      // Handle web compatibility for camera features
      try {
        await cameraController!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('⚠️ Focus mode not supported on this platform: $e');
      }
      
      try {
        await cameraController!.setFlashMode(FlashMode.off);
      } catch (e) {
        debugPrint('⚠️ Flash mode not supported on this platform: $e');
      }
      
      // Verify camera format after initialization
      debugPrint('✅ Camera initialized with format: ${cameraController!.description.lensDirection}');
      debugPrint('📸 Camera settings - Resolution: ${ResolutionPreset.low}, Format: NV21 (optimized for ML Kit)');
      debugPrint('🎥 Camera details - Name: ${frontCamera.name}, Sensor orientation: ${frontCamera.sensorOrientation}');
      isInitialized = true;
      notifyListeners();
      
      debugPrint('Camera initialized successfully');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (kIsWeb && e.toString().contains('CameraAccessDenied')) {
        debugPrint('🌐 Web browser camera access denied. Video recording will use browser fallback methods.');
      }
    }
  }
  
  Future<void> startImageStream() async {
    if (!isInitialized || cameraController == null) {
      debugPrint('Camera not initialized');
      return;
    }

    if (cameraController!.value.isStreamingImages) {
      debugPrint('Camera already streaming');
      return;
    }

    // Start cloud streaming server (works across internet)
    try {
      final cloudStreamUrl = await _cloudStreamingService.startCloudStreaming();
      if (cloudStreamUrl != null) {
        debugPrint('🌐 Cloud streaming started at: $cloudStreamUrl');
        debugPrint('📱 Admin can access live feed from anywhere at: $cloudStreamUrl');
        debugPrint('🔗 Share this URL with the vehicle owner for remote monitoring');
      } else {
        debugPrint('⚠️ Cloud streaming failed, trying local streaming...');
        // Fallback to local streaming
        final localStreamUrl = await _streamingService.startStreaming();
        if (localStreamUrl != null) {
          debugPrint('🏠 Local streaming started at: $localStreamUrl');
          debugPrint('📱 Admin can access live feed on same WiFi at: $localStreamUrl');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error starting streaming services: $e');
    }

    // Skip image stream on web platform to avoid assertion errors
    if (kIsWeb) {
      debugPrint('🌐 Web platform detected - skipping camera image stream (face detection not supported)');
      debugPrint('✅ Camera preview and streaming available, but ML Kit detection disabled for web compatibility');
      return;
    }

    try {
      await cameraController!.startImageStream((CameraImage image) {
        // Process frames asynchronously to avoid blocking
        _processFrameAsync(image);
      });
      debugPrint('📱 Mobile camera image stream started for face detection');
    } catch (e) {
      debugPrint('❌ Error starting camera image stream: $e');
      debugPrint('🔧 This might be due to platform limitations or camera permissions');
    }
  }  // Process frames asynchronously to improve performance
  void _processFrameAsync(CameraImage image) async {
    // Skip processing if already busy (non-blocking approach)
    if (isProcessing) return;
    
    isProcessing = true;
    
    try {
      // Send frame to both streaming services for live view
      _streamingService.addFrame(image);  // Local WiFi streaming
      _cloudStreamingService.addFrame(image);  // Internet streaming
      
      // Frame skipping logic for detection processing (performance optimization)
      _frameCount++;
      final now = DateTime.now();
      
      // Simplified frame skipping - only process every Nth frame
      bool shouldProcessForDetection = (_frameCount % (_frameSkipCount + 1) == 0);
      
      // Additional time-based throttling
      if (_lastFrameProcessTime != null && 
          now.difference(_lastFrameProcessTime!).inMilliseconds < _minFrameInterval) {
        shouldProcessForDetection = false;
      }
      
      if (shouldProcessForDetection) {
        // Process for detection service
        final inputImage = _convertCameraImageToInputImage(image);
        if (inputImage != null) {
          // Create a new stream controller if needed
          if (_imageStreamController == null || _imageStreamController!.isClosed) {
            _imageStreamController = StreamController<InputImage>.broadcast();
          }
          _imageStreamController!.add(inputImage);
          _lastFrameProcessTime = now;
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing frame: $e');
    } finally {
      isProcessing = false;
    }
  }
  
  Future<void> stopImageStream() async {
    if (cameraController == null || !cameraController!.value.isStreamingImages) {
      return;
    }
    
    await cameraController!.stopImageStream();
    debugPrint('Camera image stream stopped');
  }
  
  Future<void> resetImageStream() async {
    // Close the existing stream controller if it exists
    if (_imageStreamController != null && !_imageStreamController!.isClosed) {
      await _imageStreamController!.close();
    }
    // Create a new broadcast stream controller
    _imageStreamController = StreamController<InputImage>.broadcast();
    debugPrint('Camera image stream reset');
  }
  
  // Streaming control methods
  Future<String?> startLiveStreaming() async {
    return await _streamingService.startStreaming();
  }
  
  Future<void> stopLiveStreaming() async {
    await _streamingService.stopStreaming();
    await _cloudStreamingService.stopCloudStreaming();
    debugPrint('🔴 All streaming services stopped');
  }
  
  bool get isStreaming => _streamingService.isStreaming || _cloudStreamingService.isStreaming;
  String? get streamingUrl => _streamingService.serverUrl;
  String? get cloudStreamingUrl => _cloudStreamingService.streamingUrl;
  Map<String, dynamic> get cloudStreamInfo => _cloudStreamingService.getStreamInfo();
  String? get qrCodeData => _cloudStreamingService.getQRCodeData();
  
  // Video recording methods
  Future<void> startVideoRecording() async {
    if (!isInitialized || cameraController == null) {
      debugPrint('❌ Camera not initialized for video recording');
      return;
    }
    
    if (isRecording) {
      debugPrint('⚠️ Video recording already in progress');
      return;
    }
    
    try {
      // Check if running on web
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - using browser recording');
        // For web, we'll use a simplified recording approach
        await cameraController!.startVideoRecording();
        isRecording = true;
        currentVideoPath = 'web_recording_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🎥 Web video recording started');
        notifyListeners();
        return;
      }
      
      // Native platform recording
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDir.path}/videos';
      
      // Create videos directory if it doesn't exist
      final Directory videoDirObj = Directory(videoDir);
      if (!await videoDirObj.exists()) {
        await videoDirObj.create(recursive: true);
      }
      
      // Generate unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '$videoDir/saferide_recording_$timestamp.mp4';
      
      // Start recording
      await cameraController!.startVideoRecording();
      isRecording = true;
      currentVideoPath = filePath;
      
      debugPrint('🎥 Video recording started: $filePath');
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error starting video recording: $e');
      isRecording = false;
      currentVideoPath = null;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<String?> stopVideoRecording() async {
    if (!isRecording || cameraController == null) {
      debugPrint('⚠️ No video recording in progress');
      return null;
    }
    
    try {
      // Stop recording and get the file
      final XFile videoFile = await cameraController!.stopVideoRecording();
      
      if (kIsWeb) {
        // Web platform handling
        debugPrint('🌐 Web video recording stopped');
        lastRecordedVideo = videoFile;
        isRecording = false;
        currentVideoPath = null;
        notifyListeners();
        
        // For web, we can't access the actual file path, so return a user-friendly message
        return 'Video recorded successfully (Web)';
      }
      
      // Native platform handling
      if (currentVideoPath != null) {
        final File sourceFile = File(videoFile.path);
        
        if (await sourceFile.exists()) {
          await sourceFile.copy(currentVideoPath!);
          await sourceFile.delete(); // Clean up temp file
          lastRecordedVideo = XFile(currentVideoPath!);
          debugPrint('🎥 Video recording saved: $currentVideoPath');
        }
      } else {
        lastRecordedVideo = videoFile;
        currentVideoPath = videoFile.path;
        debugPrint('🎥 Video recording saved: ${videoFile.path}');
      }
      
      isRecording = false;
      final savedPath = currentVideoPath;
      currentVideoPath = null;
      notifyListeners();
      
      return savedPath;
      
    } catch (e) {
      debugPrint('❌ Error stopping video recording: $e');
      isRecording = false;
      currentVideoPath = null;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<List<String>> getRecordedVideos() async {
    try {
      if (kIsWeb) {
        // Web platform - return simplified list
        debugPrint('🌐 Web platform - limited video access');
        return lastRecordedVideo != null 
            ? ['Web Recording (${DateTime.now().toString().split(' ')[0]})']
            : [];
      }
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDir.path}/videos';
      final Directory videoDirObj = Directory(videoDir);
      
      if (!await videoDirObj.exists()) {
        return [];
      }
      
      final List<FileSystemEntity> files = await videoDirObj.list().toList();
      final List<String> videoFiles = files
          .where((file) => file is File && file.path.endsWith('.mp4'))
          .map((file) => file.path)
          .toList();
      
      // Sort by modification time (newest first)
      videoFiles.sort((a, b) {
        final aFile = File(a);
        final bFile = File(b);
        return bFile.lastModifiedSync().compareTo(aFile.lastModifiedSync());
      });
      
      return videoFiles;
    } catch (e) {
      debugPrint('❌ Error getting recorded videos: $e');
      return [];
    }
  }
  
  Future<void> deleteVideo(String videoPath) async {
    try {
      final File videoFile = File(videoPath);
      if (await videoFile.exists()) {
        await videoFile.delete();
        debugPrint('🗑️ Video deleted: $videoPath');
      }
    } catch (e) {
      debugPrint('❌ Error deleting video: $e');
      rethrow;
    }
  }

  Future<String> getVideoStoragePath() async {
    if (kIsWeb) {
      return 'Web Browser Downloads Folder';
    }
    
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDir.path}/videos';
      return videoDir;
    } catch (e) {
      debugPrint('❌ Error getting storage path: $e');
      return 'Storage path unavailable';
    }
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      if (kIsWeb) {
        return {
          'platform': 'Web',
          'location': 'Browser Downloads Folder',
          'format': 'WebM',
          'access': 'Check your Downloads folder',
          'totalVideos': lastRecordedVideo != null ? 1 : 0,
        };
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoDir = '${appDir.path}/videos';
      final Directory videoDirObj = Directory(videoDir);
      
      int totalVideos = 0;
      int totalSizeBytes = 0;
      
      if (await videoDirObj.exists()) {
        final List<FileSystemEntity> files = await videoDirObj.list().toList();
        final videoFiles = files.where((file) => file is File && file.path.endsWith('.mp4'));
        
        totalVideos = videoFiles.length;
        
        for (final file in videoFiles) {
          if (file is File) {
            totalSizeBytes += await file.length();
          }
        }
      }
      
      return {
        'platform': 'Mobile',
        'location': videoDir,
        'format': 'MP4',
        'totalVideos': totalVideos,
        'totalSizeMB': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'access': 'Through app or file manager',
      };
    } catch (e) {
      debugPrint('❌ Error getting storage info: $e');
      return {
        'platform': 'Unknown',
        'location': 'Error retrieving path',
        'format': 'Unknown',
        'totalVideos': 0,
        'totalSizeMB': '0',
        'access': 'Check app permissions',
      };
    }
  }
  
  @override
  Future<void> dispose() async {
    // Stop video recording if in progress
    if (isRecording) {
      try {
        await stopVideoRecording();
      } catch (e) {
        debugPrint('⚠️ Error stopping video recording during dispose: $e');
      }
    }
    
    await stopImageStream();
    await stopLiveStreaming();
    await _imageStreamController?.close();
    _imageStreamController = null;
    await cameraController?.dispose();
    isInitialized = false;
    super.dispose();
    debugPrint('Camera service disposed');
  }
  
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      // Get the camera description
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      // Calculate rotation based on device orientation and camera sensor
      InputImageRotation rotation = InputImageRotation.rotation0deg;
      final sensorOrientation = camera.sensorOrientation;
      
      // Adjust rotation for front camera (simplified)
      if (camera.lensDirection == CameraLensDirection.front) {
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation270deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation90deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      } else {
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      }
      
      // Simplified logging (only errors and key info)
      if (DateTime.now().millisecondsSinceEpoch % 5000 < 100) {
        debugPrint('📷 Image: ${image.width}x${image.height}, Format: ${image.format.group}, Planes: ${image.planes.length}');
      }
      
      // Use simplified approach with NV21 format
      return _createInputImageSimplified(image, rotation);
      
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }
  
  InputImage? _createInputImageSimplified(CameraImage image, InputImageRotation rotation) {
    try {
      // Use simple NV21 format conversion for better compatibility
      final firstPlane = image.planes[0];
      final bytes = firstPlane.bytes;
      
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: firstPlane.bytesPerRow,
      );
      
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      
      return inputImage;
      
    } catch (e) {
      debugPrint('❌ Failed to create InputImage: $e');
      
      // Fallback: try with minimal metadata
      try {
        final metadata = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        );
        
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: metadata,
        );
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        return null;
      }
    }
  }
}
