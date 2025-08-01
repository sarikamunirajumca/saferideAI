import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/streaming_service.dart';

class CameraService extends ChangeNotifier {
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  bool isInitialized = false;
  bool isProcessing = false;
  StreamController<InputImage>? _imageStreamController;
  final StreamingService _streamingService = StreamingService();
  
  // Frame skipping variables for performance optimization
  int _frameCount = 0;
  static const int _frameSkipCount = 1; // Process every 2nd frame for detection (reduced from 3)
  DateTime? _lastFrameProcessTime;
  static const int _minFrameInterval = 200; // Minimum 200ms between detection frames (reduced from 300ms)
  
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
        return;
      }
      
      // Select the front-facing camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Reduced resolution for faster streaming performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Use device's native format for compatibility
      );
      
      await cameraController!.initialize();
      
      // Additional camera settings for optimal performance and color
      await cameraController!.setFocusMode(FocusMode.auto);
      await cameraController!.setFlashMode(FlashMode.off);
      
      // Verify camera format after initialization
      debugPrint('✅ Camera initialized with format: ${cameraController!.description.lensDirection}');
      debugPrint('📸 Camera settings - Resolution: ${ResolutionPreset.low}, Format: YUV420 (optimized for streaming)');
      debugPrint('🎥 Camera details - Name: ${frontCamera.name}, Sensor orientation: ${frontCamera.sensorOrientation}');
      isInitialized = true;
      notifyListeners();
      
      debugPrint('Camera initialized successfully');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
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
    
    await cameraController!.startImageStream((CameraImage image) {
      // Process frames asynchronously to avoid blocking
      _processFrameAsync(image);
    });
    
    debugPrint('Camera image stream started');
  }
  
  // Process frames asynchronously to improve performance
  void _processFrameAsync(CameraImage image) async {
    // Skip processing if already busy (non-blocking approach)
    if (isProcessing) return;
    
    isProcessing = true;
    
    try {
      // Always send frame to streaming service for live view (every frame)
      _streamingService.addFrame(image);
      
      // Frame skipping logic for detection processing (performance optimization)
      _frameCount++;
      final now = DateTime.now();
      
      // Skip frames for detection processing to improve performance
      bool shouldProcessForDetection = false;
      
      // Method 1: Frame count based skipping (process every Nth frame)
      if (_frameCount % (_frameSkipCount + 1) == 0) {
        shouldProcessForDetection = true;
      }
      
      // Method 2: Time-based skipping (minimum interval between detection frames)
      if (_lastFrameProcessTime != null && 
          now.difference(_lastFrameProcessTime!).inMilliseconds < _minFrameInterval) {
        shouldProcessForDetection = false;
      }
      
      if (shouldProcessForDetection) {
        // Process for detection service (lower priority, with frame skipping)
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
  }
  
  bool get isStreaming => _streamingService.isStreaming;
  String? get streamingUrl => _streamingService.serverUrl;
  
  @override
  Future<void> dispose() async {
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
      
      // Adjust rotation for front camera
      if (camera.lensDirection == CameraLensDirection.front) {
        switch (sensorOrientation) {
          case 90:
            rotation = InputImageRotation.rotation270deg;
            break;
          case 180:
            rotation = InputImageRotation.rotation180deg;
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
          case 180:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 270:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }
      }
      
      // Debug: Log image properties (reduced frequency)
      if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
        debugPrint('Camera image format: ${image.format.group}');
        debugPrint('Image width: ${image.width}, height: ${image.height}');
        debugPrint('Number of planes: ${image.planes.length}');
        if (image.planes.isNotEmpty) {
          debugPrint('First plane bytes length: ${image.planes[0].bytes.length}');
          debugPrint('First plane bytes per row: ${image.planes[0].bytesPerRow}');
        }
      }
      
      // Use a comprehensive approach to handle different camera formats
      return _createInputImageRobust(image, rotation);
      
    } catch (e) {
      debugPrint('Error in _convertCameraImageToInputImage: $e');
      return null;
    }
  }
  
  InputImage? _createInputImageRobust(CameraImage image, InputImageRotation rotation) {
    // Try multiple approaches in order of preference
    
    // Approach 1: Try with detected format and proper byte handling
    try {
      InputImageFormat format;
      Uint8List bytes;
      int bytesPerRow;
      
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          format = InputImageFormat.yuv420;
          // YUV420 has Y, U, V planes - need to concatenate properly
          final yPlane = image.planes[0];
          final uPlane = image.planes[1];
          final vPlane = image.planes[2];
          
          final ySize = yPlane.bytes.length;
          final uvSize = uPlane.bytes.length + vPlane.bytes.length;
          
          bytes = Uint8List(ySize + uvSize);
          bytes.setRange(0, ySize, yPlane.bytes);
          bytes.setRange(ySize, ySize + uPlane.bytes.length, uPlane.bytes);
          bytes.setRange(ySize + uPlane.bytes.length, bytes.length, vPlane.bytes);
          
          bytesPerRow = yPlane.bytesPerRow;
          break;
          
        case ImageFormatGroup.nv21:
          format = InputImageFormat.nv21;
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
          break;
          
        case ImageFormatGroup.bgra8888:
          format = InputImageFormat.bgra8888;
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
          break;
          
        default:
          // Unknown format - try to convert to NV21
          format = InputImageFormat.nv21;
          bytes = image.planes[0].bytes;
          bytesPerRow = image.planes[0].bytesPerRow;
      }
      
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      );
      
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      
      // Log success occasionally
      if (DateTime.now().millisecondsSinceEpoch % 2000 < 100) {
        debugPrint('InputImage created successfully with format: $format');
      }
      
      return inputImage;
      
    } catch (e) {
      debugPrint('Approach 1 failed: $e');
    }
    
    // Approach 2: Force NV21 with single plane
    try {
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );
      
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );
      
      debugPrint('InputImage created with forced NV21 format');
      return inputImage;
      
    } catch (e) {
      debugPrint('Approach 2 failed: $e');
    }
    
    // Approach 3: Try with calculated bytes per row
    try {
      final calculatedBytesPerRow = image.width * 1.5; // Typical for NV21
      
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: calculatedBytesPerRow.round(),
      );
      
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: metadata,
      );
      
      debugPrint('InputImage created with calculated bytes per row');
      return inputImage;
      
    } catch (e) {
      debugPrint('Approach 3 failed: $e');
    }
    
    // Approach 4: Try with minimal metadata
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // Minimal bytes per row
        ),
      );
      
      debugPrint('InputImage created with minimal metadata');
      return inputImage;
      
    } catch (e) {
      debugPrint('All approaches failed: $e');
      return null;
    }
  }
}
