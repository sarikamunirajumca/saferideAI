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
        ResolutionPreset.medium, // Higher resolution for better face detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Force NV21 format
      );
      
      await cameraController!.initialize();
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
      if (isProcessing) return;
      
      isProcessing = true;
      
      // Send frame to streaming service for live viewing
      _streamingService.addFrame(image);
      
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage != null) {
        // Create a new stream controller if needed
        if (_imageStreamController == null || _imageStreamController!.isClosed) {
          _imageStreamController = StreamController<InputImage>.broadcast();
        }
        _imageStreamController!.add(inputImage);
      }
      
      isProcessing = false;
    });
    
    debugPrint('Camera image stream started');
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
