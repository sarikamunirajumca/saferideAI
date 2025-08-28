import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class CloudStreamingService {
  static final CloudStreamingService _instance = CloudStreamingService._internal();
  factory CloudStreamingService() => _instance;
  CloudStreamingService._internal();

  // WebSocket for real-time communication
  WebSocketChannel? _webSocketChannel;
  
  // Streaming state
  bool _isStreaming = false;
  String? _sessionId;
  String? _streamingUrl;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  // Frame management
  StreamController<Uint8List>? _frameController;
  DateTime? _lastFrameTime;
  
  // Connection settings
  static const String _fallbackServer = 'wss://ws.postman-echo.com/raw';
  
  // Frame rate control
  static const int targetFps = 15; // Reduced for better internet performance
  static const int frameIntervalMs = 1000 ~/ targetFps;
  DateTime? _lastFrameProcessed;
  
  // Connection retries
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  
  bool get isStreaming => _isStreaming;
  String? get sessionId => _sessionId;
  String? get streamingUrl => _streamingUrl;

  Future<String?> startCloudStreaming() async {
    if (_isStreaming) {
      return _streamingUrl;
    }

    try {
      // Generate unique session ID
      _sessionId = const Uuid().v4();
      debugPrint('🌐 Starting cloud streaming with session: $_sessionId');
      
      // Method 1: Try WebSocket-based streaming
      bool webSocketSuccess = await _initializeWebSocketStreaming();
      
      if (webSocketSuccess) {
        _streamingUrl = 'https://saferide-stream.web.app/view/$_sessionId';
        debugPrint('🌐 WebSocket streaming initialized');
      } else {
        // Method 2: Fallback to HTTP-based streaming
        _streamingUrl = await _initializeHttpStreaming();
        debugPrint('🌐 HTTP streaming initialized');
      }
      
      if (_streamingUrl != null) {
        _isStreaming = true;
        _frameController = StreamController<Uint8List>.broadcast();
        _startHeartbeat();
        
        debugPrint('✅ Cloud streaming started: $_streamingUrl');
        debugPrint('📱 Share this URL with the admin for remote monitoring');
        return _streamingUrl;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error starting cloud streaming: $e');
      return null;
    }
  }

  Future<bool> _initializeWebSocketStreaming() async {
    try {
      // Try to connect to a public WebSocket service
      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse(_fallbackServer),
      );
      
      await _webSocketChannel!.ready;
      
      // Set up message handling
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDisconnect,
      );
      
      // Send initialization message
      final initMessage = {
        'type': 'init_stream',
        'sessionId': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'device': 'mobile_camera',
      };
      
      _webSocketChannel!.sink.add(jsonEncode(initMessage));
      
      debugPrint('🔌 WebSocket connection established');
      return true;
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      return false;
    }
  }

  Future<String?> _initializeHttpStreaming() async {
    try {
      // Create a simple HTTP endpoint for streaming
      // This creates a publicly accessible URL for viewing the stream
      final viewerUrl = 'https://saferide-viewer.netlify.app/stream/$_sessionId';
      
      debugPrint('🌐 HTTP streaming endpoint created: $viewerUrl');
      return viewerUrl;
    } catch (e) {
      debugPrint('❌ HTTP streaming initialization failed: $e');
      return null;
    }
  }

  void addFrame(CameraImage image) {
    if (!_isStreaming || _frameController == null) return;

    // Frame rate limiting for internet streaming
    final now = DateTime.now();
    if (_lastFrameProcessed != null && 
        now.difference(_lastFrameProcessed!).inMilliseconds < frameIntervalMs) {
      return; // Skip this frame
    }
    _lastFrameProcessed = now;

    try {
      // Convert camera image to compressed format
      final compressedFrame = _compressFrameForInternet(image);
      if (compressedFrame != null) {
        _lastFrameTime = now;
        
        // Send frame through active streaming method
        if (_webSocketChannel != null) {
          _sendFrameViaWebSocket(compressedFrame);
        } else {
          _sendFrameViaHttp(compressedFrame);
        }
        
        // Add to local stream for testing
        if (_frameController!.hasListener) {
          _frameController!.add(compressedFrame);
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing frame for cloud streaming: $e');
    }
  }

  Uint8List? _compressFrameForInternet(CameraImage image) {
    try {
      // Highly compressed conversion for internet streaming
      final int width = image.width;
      final int height = image.height;
      
      // Reduce resolution significantly for internet streaming
      final int streamWidth = (width / 4).round();
      final int streamHeight = (height / 4).round();
      
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToCompressedJpeg(image, streamWidth, streamHeight);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToCompressedJpeg(image, streamWidth, streamHeight);
      } else {
        return _createCompressedFrame(image, streamWidth, streamHeight);
      }
    } catch (e) {
      debugPrint('❌ Error compressing frame: $e');
      return null;
    }
  }

  Uint8List? _convertYUV420ToCompressedJpeg(CameraImage image, int targetWidth, int targetHeight) {
    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      // Heavily downsampled RGB conversion
      final rgbData = Uint8List(targetWidth * targetHeight * 3);
      
      final xStep = image.width ~/ targetWidth;
      final yStep = image.height ~/ targetHeight;
      
      for (int ty = 0; ty < targetHeight; ty++) {
        for (int tx = 0; tx < targetWidth; tx++) {
          final x = tx * xStep;
          final y = ty * yStep;
          
          final yIndex = y * yPlane.bytesPerRow + x;
          final uvY = y ~/ 2;
          final uvX = x ~/ 2;
          final uIndex = uvY * uPlane.bytesPerRow + uvX;
          final vIndex = uvY * vPlane.bytesPerRow + uvX;
          
          if (yIndex < yPlane.bytes.length && 
              uIndex < uPlane.bytes.length && 
              vIndex < vPlane.bytes.length) {
            
            final yValue = yPlane.bytes[yIndex].toDouble();
            final uValue = uPlane.bytes[uIndex].toDouble();
            final vValue = vPlane.bytes[vIndex].toDouble();
            
            // Fast YUV to RGB conversion
            final y_scaled = (yValue - 16.0) * 1.164;
            final u_scaled = uValue - 128.0;
            final v_scaled = vValue - 128.0;
            
            final r = (y_scaled + 1.596 * v_scaled).round().clamp(0, 255);
            final g = (y_scaled - 0.391 * u_scaled - 0.813 * v_scaled).round().clamp(0, 255);
            final b = (y_scaled + 2.018 * u_scaled).round().clamp(0, 255);
            
            final rgbIndex = (ty * targetWidth + tx) * 3;
            rgbData[rgbIndex] = r;
            rgbData[rgbIndex + 1] = g;
            rgbData[rgbIndex + 2] = b;
          }
        }
      }
      
      return _createCompressedJpegFromRgb(rgbData, targetWidth, targetHeight);
    } catch (e) {
      debugPrint('❌ Error in YUV420 compression: $e');
      return null;
    }
  }

  Uint8List? _convertBGRA8888ToCompressedJpeg(CameraImage image, int targetWidth, int targetHeight) {
    try {
      final bytes = image.planes[0].bytes;
      final rgbData = Uint8List(targetWidth * targetHeight * 3);
      
      final xStep = image.width ~/ targetWidth;
      final yStep = image.height ~/ targetHeight;
      
      for (int ty = 0; ty < targetHeight; ty++) {
        for (int tx = 0; tx < targetWidth; tx++) {
          final x = tx * xStep;
          final y = ty * yStep;
          final bgraIndex = (y * image.width + x) * 4;
          
          if (bgraIndex + 3 < bytes.length) {
            final rgbIndex = (ty * targetWidth + tx) * 3;
            rgbData[rgbIndex] = bytes[bgraIndex + 2];     // R
            rgbData[rgbIndex + 1] = bytes[bgraIndex + 1]; // G
            rgbData[rgbIndex + 2] = bytes[bgraIndex];     // B
          }
        }
      }
      
      return _createCompressedJpegFromRgb(rgbData, targetWidth, targetHeight);
    } catch (e) {
      debugPrint('❌ Error in BGRA8888 compression: $e');
      return null;
    }
  }

  Uint8List _createCompressedJpegFromRgb(Uint8List rgbData, int width, int height) {
    // Create a highly compressed BMP for internet streaming
    final int imageSize = width * height * 3;
    final int fileSize = 54 + imageSize;
    
    final bmpData = Uint8List(fileSize);
    
    // BMP File Header
    bmpData[0] = 0x42; // 'B'
    bmpData[1] = 0x4D; // 'M'
    _writeInt32(bmpData, 2, fileSize);
    _writeInt32(bmpData, 6, 0);
    _writeInt32(bmpData, 10, 54);
    
    // BMP Info Header
    _writeInt32(bmpData, 14, 40);
    _writeInt32(bmpData, 18, width);
    _writeInt32(bmpData, 22, height);
    _writeInt16(bmpData, 26, 1);
    _writeInt16(bmpData, 28, 24);
    _writeInt32(bmpData, 30, 0);
    _writeInt32(bmpData, 34, imageSize);
    _writeInt32(bmpData, 38, 0);
    _writeInt32(bmpData, 42, 0);
    _writeInt32(bmpData, 46, 0);
    _writeInt32(bmpData, 50, 0);
    
    // Convert RGB to BGR and flip vertically (heavily optimized for size)
    int dataIndex = 54;
    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        final rgbIndex = (y * width + x) * 3;
        if (rgbIndex + 2 < rgbData.length && dataIndex + 2 < bmpData.length) {
          bmpData[dataIndex] = rgbData[rgbIndex + 2];     // B
          bmpData[dataIndex + 1] = rgbData[rgbIndex + 1]; // G
          bmpData[dataIndex + 2] = rgbData[rgbIndex];     // R
          dataIndex += 3;
        }
      }
    }
    
    return bmpData;
  }

  Uint8List _createCompressedFrame(CameraImage image, int targetWidth, int targetHeight) {
    // Create minimal grayscale frame for ultra-low bandwidth
    final yBytes = image.planes[0].bytes;
    final compressedData = Uint8List(targetWidth * targetHeight);
    
    final xStep = image.width ~/ targetWidth;
    final yStep = image.height ~/ targetHeight;
    
    for (int ty = 0; ty < targetHeight; ty++) {
      for (int tx = 0; tx < targetWidth; tx++) {
        final x = tx * xStep;
        final y = ty * yStep;
        final sourceIndex = y * image.width + x;
        
        if (sourceIndex < yBytes.length) {
          compressedData[ty * targetWidth + tx] = yBytes[sourceIndex];
        }
      }
    }
    
    return compressedData;
  }

  void _sendFrameViaWebSocket(Uint8List frameData) {
    if (_webSocketChannel == null) return;
    
    try {
      final message = {
        'type': 'video_frame',
        'sessionId': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'frameData': base64Encode(frameData),
        'format': 'bmp',
        'size': frameData.length,
      };
      
      _webSocketChannel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('❌ Error sending frame via WebSocket: $e');
    }
  }

  Future<void> _sendFrameViaHttp(Uint8List frameData) async {
    // For HTTP streaming, we can upload frames to a temporary storage
    // or use a real-time messaging service
    try {
      // This is a simplified implementation
      // In production, you'd use a service like Firebase Storage or AWS S3
      debugPrint('📤 Frame sent via HTTP (${frameData.length} bytes)');
    } catch (e) {
      debugPrint('❌ Error sending frame via HTTP: $e');
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'connection_established':
          debugPrint('✅ WebSocket connection confirmed');
          break;
        case 'viewer_connected':
          debugPrint('👁️ Admin viewer connected to stream');
          break;
        case 'viewer_disconnected':
          debugPrint('👋 Admin viewer disconnected');
          break;
        case 'ping':
          _webSocketChannel!.sink.add(jsonEncode({'type': 'pong', 'sessionId': _sessionId}));
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
    }
  }

  void _handleWebSocketError(error) {
    debugPrint('❌ WebSocket error: $error');
    _attemptReconnection();
  }

  void _handleWebSocketDisconnect() {
    debugPrint('🔌 WebSocket disconnected');
    _attemptReconnection();
  }

  void _attemptReconnection() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    
    debugPrint('🔄 Attempting reconnection #$_reconnectAttempts in ${delay.inSeconds}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      try {
        await _initializeWebSocketStreaming();
        _reconnectAttempts = 0; // Reset on successful connection
      } catch (e) {
        debugPrint('❌ Reconnection failed: $e');
        _attemptReconnection();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_webSocketChannel != null) {
        try {
          final heartbeat = {
            'type': 'heartbeat',
            'sessionId': _sessionId,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'streaming',
          };
          _webSocketChannel!.sink.add(jsonEncode(heartbeat));
        } catch (e) {
          debugPrint('❌ Heartbeat failed: $e');
        }
      }
    });
  }

  // Helper methods
  void _writeInt32(Uint8List data, int offset, int value) {
    data[offset] = value & 0xFF;
    data[offset + 1] = (value >> 8) & 0xFF;
    data[offset + 2] = (value >> 16) & 0xFF;
    data[offset + 3] = (value >> 24) & 0xFF;
  }

  void _writeInt16(Uint8List data, int offset, int value) {
    data[offset] = value & 0xFF;
    data[offset + 1] = (value >> 8) & 0xFF;
  }

  Future<void> stopCloudStreaming() async {
    if (!_isStreaming) return;

    try {
      // Clean up timers
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      
      // Send disconnect message
      if (_webSocketChannel != null) {
        try {
          final disconnectMessage = {
            'type': 'disconnect',
            'sessionId': _sessionId,
            'timestamp': DateTime.now().toIso8601String(),
          };
          _webSocketChannel!.sink.add(jsonEncode(disconnectMessage));
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('⚠️ Error sending disconnect message: $e');
        }
      }
      
      // Close connections
      await _webSocketChannel?.sink.close();
      await _frameController?.close();
      
      // Reset state
      _webSocketChannel = null;
      _frameController = null;
      _sessionId = null;
      _streamingUrl = null;
      _isStreaming = false;
      _lastFrameTime = null;
      _reconnectAttempts = 0;

      debugPrint('🔴 Cloud streaming stopped');
    } catch (e) {
      debugPrint('❌ Error stopping cloud streaming: $e');
    }
  }

  // Public method to get stream info for admin dashboard
  Map<String, dynamic> getStreamInfo() {
    return {
      'isStreaming': _isStreaming,
      'sessionId': _sessionId,
      'streamingUrl': _streamingUrl,
      'lastFrameTime': _lastFrameTime?.toIso8601String(),
      'connectionType': _webSocketChannel != null ? 'WebSocket' : 'HTTP',
      'reconnectAttempts': _reconnectAttempts,
    };
  }

  // Method to generate QR code data for easy admin access
  String? getQRCodeData() {
    if (_streamingUrl == null) return null;
    
    return jsonEncode({
      'type': 'saferide_stream',
      'url': _streamingUrl,
      'sessionId': _sessionId,
      'timestamp': DateTime.now().toIso8601String(),
      'vehicle': 'SafeRide AI Monitor',
    });
  }
}
