import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:network_info_plus/network_info_plus.dart';

class StreamingService {
  static final StreamingService _instance = StreamingService._internal();
  factory StreamingService() => _instance;
  StreamingService._internal();

  HttpServer? _server;
  StreamController<Uint8List>? _frameController;
  String? _serverUrl;
  bool _isStreaming = false;
  Timer? _keepAliveTimer;
  
  // Current frame data
  Uint8List? _currentFrame;
  DateTime? _lastFrameTime;
  
  // Frame rate limiting - optimized for smoother streaming
  static const int targetFps = 30; // Increased to 30 FPS for better responsiveness
  static const int frameIntervalMs = 1000 ~/ targetFps; // ~33ms between frames
  DateTime? _lastFrameProcessed;
  
  bool get isStreaming => _isStreaming;
  String? get serverUrl => _serverUrl;

  Future<String?> startStreaming() async {
    if (_isStreaming) {
      return _serverUrl;
    }

    try {
      // Get device IP address
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP == null) {
        debugPrint('❌ Could not get WiFi IP address');
        return null;
      }

      // Create frame stream controller
      _frameController = StreamController<Uint8List>.broadcast();

      // Create router
      final router = Router();

      // Serve the web viewer page
      router.get('/', _serveWebPage);
      
      // Stream endpoint for MJPEG
      router.get('/stream', _streamHandler);
      
      // Status endpoint
      router.get('/status', _statusHandler);

      // Start the server
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware)
          .addHandler(router);

      _server = await io.serve(handler, wifiIP, 8080);
      _serverUrl = 'http://$wifiIP:8080';
      _isStreaming = true;

      // Start keep-alive timer
      _startKeepAliveTimer();

      debugPrint('🌐 Live streaming server started at: $_serverUrl');
      return _serverUrl;
    } catch (e) {
      debugPrint('❌ Error starting streaming server: $e');
      return null;
    }
  }

  Future<void> stopStreaming() async {
    if (!_isStreaming) return;

    try {
      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;
      
      await _server?.close(force: true);
      await _frameController?.close();
      
      _server = null;
      _frameController = null;
      _serverUrl = null;
      _isStreaming = false;
      _currentFrame = null;
      _lastFrameTime = null;

      debugPrint('🔴 Live streaming server stopped');
    } catch (e) {
      debugPrint('❌ Error stopping streaming server: $e');
    }
  }

  void addFrame(CameraImage image) {
    if (!_isStreaming || _frameController == null) return;

    // Optimized frame rate limiting - more aggressive for better responsiveness
    final now = DateTime.now();
    if (_lastFrameProcessed != null && 
        now.difference(_lastFrameProcessed!).inMilliseconds < (frameIntervalMs ~/ 2)) {
      return; // Skip this frame, but with reduced interval for better performance
    }
    _lastFrameProcessed = now;

    try {
      // Minimal logging for performance
      if (DateTime.now().millisecondsSinceEpoch % 15000 < 100) { // Every 15 seconds
        debugPrint('📹 Processing frame - Format: ${image.format.group}, Size: ${image.width}x${image.height}');
      }
      
      // Convert camera image to JPEG with optimized conversion
      final jpegBytes = _convertCameraImageToJpeg(image);
      if (jpegBytes != null) {
        _currentFrame = jpegBytes;
        _lastFrameTime = now;
        
        // Add to stream if there are listeners
        if (_frameController!.hasListener) {
          _frameController!.add(jpegBytes);
        }
      }
    } catch (e) {
      debugPrint('❌ Error processing frame for stream: $e');
    }
  }

  Uint8List? _convertCameraImageToJpeg(CameraImage image) {
    try {
      // Prioritize BGRA8888 for best performance and color quality
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToJpeg(image);
      } else if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToJpeg(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToJpeg(image);
      }
      
      // Fallback: try to create a basic frame from the first plane
      return _createBasicJpegFrame(image);
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }

  Uint8List? _convertYUV420ToJpeg(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      
      // Reduce resolution for faster streaming (quarter size)
      final int streamWidth = width ~/ 2;
      final int streamHeight = height ~/ 2;
      
      // Get Y, U, V planes
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      // Create RGB data from YUV420 with reduced resolution
      final rgbData = _yuv420ToRgbOptimized(
        yPlane.bytes, uPlane.bytes, vPlane.bytes,
        width, height, streamWidth, streamHeight,
        yPlane.bytesPerRow, uPlane.bytesPerRow, vPlane.bytesPerRow
      );
      
      // Create a simple JPEG-like structure
      return _createJpegFromRgb(rgbData, streamWidth, streamHeight);
    } catch (e) {
      debugPrint('❌ Error in YUV420 conversion: $e');
      return _createBasicJpegFrame(image);
    }
  }

  Uint8List? _convertNV21ToJpeg(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      
      // Get Y and UV planes
      final yPlane = image.planes[0].bytes;
      final uvPlane = image.planes.length > 1 ? image.planes[1].bytes : null;
      
      // Convert NV21 to RGB
      final rgbData = _nv21ToRgb(yPlane, uvPlane, width, height);
      
      // Create JPEG from RGB data
      return _createJpegFromRgb(rgbData, width, height);
    } catch (e) {
      debugPrint('❌ Error in NV21 conversion: $e');
      return _createBasicJpegFrame(image);
    }
  }

  Uint8List? _convertBGRA8888ToJpeg(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final bytes = image.planes[0].bytes;
      
      // Convert BGRA to RGB
      final rgbData = Uint8List(width * height * 3);
      for (int i = 0; i < width * height; i++) {
        final bgraIndex = i * 4;
        final rgbIndex = i * 3;
        if (bgraIndex + 3 < bytes.length && rgbIndex + 2 < rgbData.length) {
          rgbData[rgbIndex] = bytes[bgraIndex + 2];     // R
          rgbData[rgbIndex + 1] = bytes[bgraIndex + 1]; // G
          rgbData[rgbIndex + 2] = bytes[bgraIndex];     // B
        }
      }
      
      return _createJpegFromRgb(rgbData, width, height);
    } catch (e) {
      debugPrint('❌ Error in BGRA8888 conversion: $e');
      return _createBasicJpegFrame(image);
    }
  }

  // Optimized YUV420 to RGB conversion with reduced resolution for faster streaming
  Uint8List _yuv420ToRgbOptimized(
      Uint8List yPlane, Uint8List uPlane, Uint8List vPlane,
      int originalWidth, int originalHeight, int targetWidth, int targetHeight,
      int yRowStride, int uRowStride, int vRowStride) {
    
    final rgbData = Uint8List(targetWidth * targetHeight * 3);
    
    // Sample every 2nd pixel for reduced resolution and faster processing
    final xStep = originalWidth ~/ targetWidth;
    final yStep = originalHeight ~/ targetHeight;
    
    for (int ty = 0; ty < targetHeight; ty++) {
      for (int tx = 0; tx < targetWidth; tx++) {
        final x = tx * xStep;
        final y = ty * yStep;
        
        final yIndex = y * yRowStride + x;
        
        // For YUV420, UV planes are subsampled by 2 in both dimensions
        final uvY = y ~/ 2;
        final uvX = x ~/ 2;
        final uIndex = uvY * uRowStride + uvX;
        final vIndex = uvY * vRowStride + uvX;
        
        if (yIndex < yPlane.length && uIndex < uPlane.length && vIndex < vPlane.length) {
          final yValue = yPlane[yIndex].toDouble();
          final uValue = uPlane[uIndex].toDouble();
          final vValue = vPlane[vIndex].toDouble();
          
          // Fast YUV to RGB conversion
          final y_scaled = (yValue - 16.0) * 1.164;
          final u_scaled = uValue - 128.0;
          final v_scaled = vValue - 128.0;
          
          final r = (y_scaled + 1.596 * v_scaled).round().clamp(0, 255);
          final g = (y_scaled - 0.391 * u_scaled - 0.813 * v_scaled).round().clamp(0, 255);
          final b = (y_scaled + 2.018 * u_scaled).round().clamp(0, 255);
          
          final rgbIndex = (ty * targetWidth + tx) * 3;
          if (rgbIndex + 2 < rgbData.length) {
            rgbData[rgbIndex] = r;
            rgbData[rgbIndex + 1] = g;
            rgbData[rgbIndex + 2] = b;
          }
        }
      }
    }
    
    return rgbData;
  }

  Uint8List _yuv420ToRgb(
      Uint8List yPlane, Uint8List uPlane, Uint8List vPlane,
      int width, int height,
      int yRowStride, int uRowStride, int vRowStride) {
    
    final rgbData = Uint8List(width * height * 3);
    
    // Reduced logging frequency to improve performance (every 10 seconds)
    if (DateTime.now().millisecondsSinceEpoch % 10000 < 100) {
      debugPrint('🎨 YUV420 to RGB conversion - Size: ${width}x${height}');
    }
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        
        // For YUV420, UV planes are subsampled by 2 in both dimensions
        final uvY = y ~/ 2;
        final uvX = x ~/ 2;
        final uIndex = uvY * uRowStride + uvX;
        final vIndex = uvY * vRowStride + uvX;
        
        if (yIndex < yPlane.length && uIndex < uPlane.length && vIndex < vPlane.length) {
          final yValue = yPlane[yIndex].toDouble();
          final uValue = uPlane[uIndex].toDouble();
          final vValue = vPlane[vIndex].toDouble();
          
          // Enhanced ITU-R BT.601 conversion with proper scaling
          // Convert to full range RGB (0-255)
          final y_scaled = (yValue - 16.0) * 1.164;
          final u_scaled = uValue - 128.0;
          final v_scaled = vValue - 128.0;
          
          // More precise conversion coefficients for better color reproduction
          final r = (y_scaled + 1.596 * v_scaled).round().clamp(0, 255);
          final g = (y_scaled - 0.391 * u_scaled - 0.813 * v_scaled).round().clamp(0, 255);
          final b = (y_scaled + 2.018 * u_scaled).round().clamp(0, 255);
          
          final rgbIndex = (y * width + x) * 3;
          if (rgbIndex + 2 < rgbData.length) {
            rgbData[rgbIndex] = r;
            rgbData[rgbIndex + 1] = g;
            rgbData[rgbIndex + 2] = b;
          }
        }
      }
    }
    
    // Log some sample RGB values for debugging (reduced frequency)
    if (DateTime.now().millisecondsSinceEpoch % 10000 < 100 && rgbData.length >= 9) { // Every 10 seconds
      debugPrint('🎨 Sample RGB values: R1=${rgbData[0]}, G1=${rgbData[1]}, B1=${rgbData[2]}');
    }
    
    return rgbData;
  }

  Uint8List _nv21ToRgb(Uint8List yPlane, Uint8List? uvPlane, int width, int height) {
    final rgbData = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        
        if (yIndex < yPlane.length) {
          final yValue = yPlane[yIndex];
          
          // Get U and V values with proper NV21 format handling
          int uValue = 128;
          int vValue = 128;
          
          if (uvPlane != null && uvPlane.isNotEmpty) {
            final uvIndex = (y ~/ 2) * width + (x & ~1);
            if (uvIndex + 1 < uvPlane.length) {
              vValue = uvPlane[uvIndex];     // V comes first in NV21
              uValue = uvPlane[uvIndex + 1]; // U comes second
            }
          }
          
          // Optimized YUV to RGB conversion for better color accuracy
          final c = yValue - 16;
          final d = uValue - 128;
          final e = vValue - 128;
          
          final r = ((298 * c + 409 * e + 128) >> 8).clamp(0, 255);
          final g = ((298 * c - 100 * d - 208 * e + 128) >> 8).clamp(0, 255);
          final b = ((298 * c + 516 * d + 128) >> 8).clamp(0, 255);
          
          final rgbIndex = y * width * 3 + x * 3;
          if (rgbIndex + 2 < rgbData.length) {
            rgbData[rgbIndex] = r;
            rgbData[rgbIndex + 1] = g;
            rgbData[rgbIndex + 2] = b;
          }
        }
      }
    }
    
    return rgbData;
  }

  Uint8List _createJpegFromRgb(Uint8List rgbData, int width, int height) {
    // Create a simple uncompressed image format that's more compact than PPM
    // Use a basic BMP format which is smaller and widely supported
    return _createBmpFromRgb(rgbData, width, height);
  }

  Uint8List _createBmpFromRgb(Uint8List rgbData, int width, int height) {
    // Create a simple 24-bit BMP image
    final int imageSize = width * height * 3;
    final int fileSize = 54 + imageSize; // BMP header is 54 bytes
    
    final bmpData = Uint8List(fileSize);
    
    // BMP File Header (14 bytes)
    bmpData[0] = 0x42; // 'B'
    bmpData[1] = 0x4D; // 'M'
    _writeInt32(bmpData, 2, fileSize); // File size
    _writeInt32(bmpData, 6, 0); // Reserved
    _writeInt32(bmpData, 10, 54); // Offset to image data
    
    // BMP Info Header (40 bytes)
    _writeInt32(bmpData, 14, 40); // Header size
    _writeInt32(bmpData, 18, width); // Image width
    _writeInt32(bmpData, 22, height); // Image height
    _writeInt16(bmpData, 26, 1); // Color planes
    _writeInt16(bmpData, 28, 24); // Bits per pixel
    _writeInt32(bmpData, 30, 0); // Compression (none)
    _writeInt32(bmpData, 34, imageSize); // Image size
    _writeInt32(bmpData, 38, 0); // X pixels per meter
    _writeInt32(bmpData, 42, 0); // Y pixels per meter
    _writeInt32(bmpData, 46, 0); // Colors used
    _writeInt32(bmpData, 50, 0); // Important colors
    
    // Convert RGB to BGR (BMP uses BGR format) and flip vertically
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

  Uint8List _createBasicJpegFrame(CameraImage image) {
    try {
      // Create a simple grayscale image from the Y plane
      final width = image.width;
      final height = image.height;
      final yBytes = image.planes[0].bytes;
      
      // Convert grayscale to RGB
      final rgbData = Uint8List(width * height * 3);
      for (int i = 0; i < width * height && i < yBytes.length; i++) {
        final gray = yBytes[i];
        rgbData[i * 3] = gray;     // R
        rgbData[i * 3 + 1] = gray; // G
        rgbData[i * 3 + 2] = gray; // B
      }
      
      return _createJpegFromRgb(rgbData, width, height);
    } catch (e) {
      debugPrint('❌ Error creating basic frame: $e');
      return Uint8List(0);
    }
  }

  Response _serveWebPage(Request request) {
    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SafeRide AI - Live Monitor</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #0A0E1A, #1E2A3A);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .header {
            background: rgba(0, 0, 0, 0.5);
            padding: 1rem 2rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            backdrop-filter: blur(10px);
        }
        
        .logo {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            font-size: 1.5rem;
            font-weight: bold;
            color: #3B82F6;
        }
        
        .status {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: rgba(16, 185, 129, 0.2);
            border: 1px solid #10B981;
            border-radius: 1rem;
            font-size: 0.9rem;
        }
        
        .status-dot {
            width: 8px;
            height: 8px;
            background: #10B981;
            border-radius: 50%;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
        
        .container {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 2rem;
            gap: 2rem;
        }
        
        .video-container {
            position: relative;
            background: rgba(0, 0, 0, 0.8);
            border-radius: 1rem;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            border: 2px solid rgba(59, 130, 246, 0.3);
            width: 95vw;
            height: 75vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .video-stream {
            width: 100%;
            height: 100%;
            object-fit: cover;
            transform: scaleX(-1); /* Mirror horizontally for front camera */
        }
        
        .video-overlay {
            position: absolute;
            top: 1rem;
            left: 1rem;
            right: 1rem;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }
        
        .alert-badge {
            background: rgba(239, 68, 68, 0.9);
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 0.5rem;
            font-size: 0.9rem;
            font-weight: bold;
            backdrop-filter: blur(10px);
        }
        
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1rem;
            width: 100%;
            max-width: 800px;
        }
        
        .info-card {
            background: rgba(30, 42, 58, 0.6);
            border: 1px solid rgba(59, 130, 246, 0.2);
            border-radius: 0.75rem;
            padding: 1.5rem;
            backdrop-filter: blur(10px);
        }
        
        .info-card h3 {
            color: #3B82F6;
            font-size: 1.1rem;
            margin-bottom: 0.5rem;
        }
        
        .info-card p {
            color: rgba(255, 255, 255, 0.8);
            line-height: 1.5;
        }
        
        .connection-info {
            background: rgba(30, 42, 58, 0.4);
            border: 1px solid rgba(59, 130, 246, 0.2);
            border-radius: 0.75rem;
            padding: 1rem;
            text-align: center;
            font-size: 0.9rem;
            color: rgba(255, 255, 255, 0.7);
        }
        
        @media (max-width: 768px) {
            .header {
                padding: 1rem;
                flex-direction: column;
                gap: 1rem;
            }
            
            .container {
                padding: 1rem;
            }
            
            .info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">
            🛡️ SafeRide AI Monitor
        </div>
        <div class="status">
            <div class="status-dot"></div>
            LIVE STREAMING
        </div>
    </div>
    
    <div class="container">
        <div class="video-container">
            <img class="video-stream" src="/stream" alt="Live Camera Feed" id="videoStream">
            <div class="video-overlay">
                <div class="alert-badge" id="alertBadge" style="display: none;">
                    ⚠️ SAFETY ALERT
                </div>
            </div>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>📹 Live Monitoring</h3>
                <p>Real-time video feed from the vehicle's safety monitoring system. The AI continuously analyzes driver behavior and vehicle conditions.</p>
            </div>
            
            <div class="info-card">
                <h3>🤖 AI Detection</h3>
                <p>Advanced machine learning algorithms monitor for drowsiness, distraction, yawning, and other safety concerns in real-time.</p>
            </div>
            
            <div class="info-card">
                <h3>🔔 Instant Alerts</h3>
                <p>Immediate notifications when safety issues are detected, allowing for quick intervention and assistance.</p>
            </div>
            
            <div class="info-card">
                <h3>📱 Remote Access</h3>
                <p>Monitor your vehicle from anywhere with an internet connection. Perfect for fleet management or family safety.</p>
            </div>
        </div>
        
        <div class="connection-info">
            Connected to SafeRide AI System • Stream Quality: Auto • Latency: &lt;500ms
        </div>
    </div>
    
    <script>
        // Handle image loading errors
        const videoStream = document.getElementById('videoStream');
        let retryCount = 0;
        const maxRetries = 5;
        
        videoStream.onerror = function() {
            if (retryCount < maxRetries) {
                retryCount++;
                setTimeout(() => {
                    videoStream.src = '/stream?' + Date.now();
                }, 1000 * retryCount);
            }
        };
        
        videoStream.onload = function() {
            retryCount = 0;
        };
        
        // Refresh stream periodically to ensure freshness
        setInterval(() => {
            if (retryCount === 0) {
                const currentSrc = videoStream.src;
                videoStream.src = '';
                videoStream.src = currentSrc + '?' + Date.now();
            }
        }, 30000); // Refresh every 30 seconds
        
        // Check server status periodically
        setInterval(async () => {
            try {
                const response = await fetch('/status');
                const status = await response.json();
                // Update UI based on status if needed
            } catch (e) {
                console.log('Status check failed:', e);
            }
        }, 5000);
    </script>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
  }

  Response _streamHandler(Request request) {
    if (_frameController == null) {
      return Response.notFound('Stream not available');
    }

    // MJPEG stream response
    return Response.ok(
      _mjpegStream(),
      headers: {
        'Content-Type': 'multipart/x-mixed-replace; boundary=frame',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Connection': 'keep-alive',
      },
    );
  }

  Stream<List<int>> _mjpegStream() async* {
    const boundary = 'frame';
    
    yield utf8.encode('--$boundary\r\n');
    
    if (_currentFrame != null) {
      yield utf8.encode('Content-Type: image/bmp\r\n');
      yield utf8.encode('Content-Length: ${_currentFrame!.length}\r\n\r\n');
      yield _currentFrame!;
      yield utf8.encode('\r\n--$boundary\r\n');
    }

    await for (final frame in _frameController!.stream) {
      try {
        yield utf8.encode('Content-Type: image/bmp\r\n');
        yield utf8.encode('Content-Length: ${frame.length}\r\n\r\n');
        yield frame;
        yield utf8.encode('\r\n--$boundary\r\n');
      } catch (e) {
        debugPrint('❌ Error streaming frame: $e');
        break;
      }
    }
  }

  Response _statusHandler(Request request) {
    final status = {
      'streaming': _isStreaming,
      'clients': _frameController?.hasListener ?? false,
      'lastFrame': _lastFrameTime?.toIso8601String(),
      'serverUrl': _serverUrl,
    };

    return Response.ok(
      jsonEncode(status),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Middleware _corsMiddleware = createMiddleware(
    requestHandler: (Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      }
      return null;
    },
    responseHandler: (Response response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        ...response.headers,
      });
    },
  );

  void _startKeepAliveTimer() {
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      debugPrint('🔄 Streaming server keep-alive - Active: $_isStreaming');
    });
  }
}
