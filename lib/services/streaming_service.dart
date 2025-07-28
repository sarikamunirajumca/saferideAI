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

    try {
      // Convert camera image to JPEG bytes
      final jpegBytes = _convertCameraImageToJpeg(image);
      if (jpegBytes != null) {
        _currentFrame = jpegBytes;
        _lastFrameTime = DateTime.now();
        
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
      // Convert camera image to RGB format, then encode as JPEG
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToJpeg(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21ToJpeg(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToJpeg(image);
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
      
      // Get Y, U, V planes
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      // Create RGB data from YUV420
      final rgbData = _yuv420ToRgb(
        yPlane.bytes, uPlane.bytes, vPlane.bytes,
        width, height,
        yPlane.bytesPerRow, uPlane.bytesPerRow, vPlane.bytesPerRow
      );
      
      // Create a simple JPEG-like structure
      return _createJpegFromRgb(rgbData, width, height);
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

  Uint8List _yuv420ToRgb(
      Uint8List yPlane, Uint8List uPlane, Uint8List vPlane,
      int width, int height,
      int yRowStride, int uRowStride, int vRowStride) {
    
    final rgbData = Uint8List(width * height * 3);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uRowStride + (x ~/ 2);
        
        if (yIndex < yPlane.length && uvIndex < uPlane.length && uvIndex < vPlane.length) {
          final yValue = yPlane[yIndex];
          final uValue = uPlane[uvIndex];
          final vValue = vPlane[uvIndex];
          
          // YUV to RGB conversion
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
          
          final rgbIndex = (y * width + x) * 3;
          rgbData[rgbIndex] = r;
          rgbData[rgbIndex + 1] = g;
          rgbData[rgbIndex + 2] = b;
        }
      }
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
          
          // For grayscale fallback if UV plane is not available
          int uValue = 128;
          int vValue = 128;
          
          if (uvPlane != null) {
            final uvIndex = (y ~/ 2) * width + (x & ~1);
            if (uvIndex + 1 < uvPlane.length) {
              vValue = uvPlane[uvIndex];
              uValue = uvPlane[uvIndex + 1];
            }
          }
          
          // YUV to RGB conversion
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();
          
          final rgbIndex = y * width * 3 + x * 3;
          rgbData[rgbIndex] = r;
          rgbData[rgbIndex + 1] = g;
          rgbData[rgbIndex + 2] = b;
        }
      }
    }
    
    return rgbData;
  }

  Uint8List _createJpegFromRgb(Uint8List rgbData, int width, int height) {
    // Create a simple bitmap header + RGB data
    // This creates a basic image format that browsers can display
    
    final header = _createBitmapHeader(width, height);
    final imageData = Uint8List(header.length + rgbData.length);
    
    imageData.setRange(0, header.length, header);
    imageData.setRange(header.length, imageData.length, rgbData);
    
    return imageData;
  }

  Uint8List _createBitmapHeader(int width, int height) {
    // Create a simple BMP header
    final fileSize = 54 + (width * height * 3);
    final header = Uint8List(54);
    
    // BMP signature
    header[0] = 0x42; // 'B'
    header[1] = 0x4D; // 'M'
    
    // File size
    header[2] = fileSize & 0xFF;
    header[3] = (fileSize >> 8) & 0xFF;
    header[4] = (fileSize >> 16) & 0xFF;
    header[5] = (fileSize >> 24) & 0xFF;
    
    // Reserved
    header[6] = 0;
    header[7] = 0;
    header[8] = 0;
    header[9] = 0;
    
    // Data offset
    header[10] = 54;
    header[11] = 0;
    header[12] = 0;
    header[13] = 0;
    
    // Header size
    header[14] = 40;
    header[15] = 0;
    header[16] = 0;
    header[17] = 0;
    
    // Width
    header[18] = width & 0xFF;
    header[19] = (width >> 8) & 0xFF;
    header[20] = (width >> 16) & 0xFF;
    header[21] = (width >> 24) & 0xFF;
    
    // Height (negative for top-down)
    final negHeight = -height;
    header[22] = negHeight & 0xFF;
    header[23] = (negHeight >> 8) & 0xFF;
    header[24] = (negHeight >> 16) & 0xFF;
    header[25] = (negHeight >> 24) & 0xFF;
    
    // Planes
    header[26] = 1;
    header[27] = 0;
    
    // Bits per pixel
    header[28] = 24;
    header[29] = 0;
    
    // Compression (0 = none)
    header[30] = 0;
    header[31] = 0;
    header[32] = 0;
    header[33] = 0;
    
    // Image size
    final imageSize = width * height * 3;
    header[34] = imageSize & 0xFF;
    header[35] = (imageSize >> 8) & 0xFF;
    header[36] = (imageSize >> 16) & 0xFF;
    header[37] = (imageSize >> 24) & 0xFF;
    
    // X pixels per meter
    header[38] = 0;
    header[39] = 0;
    header[40] = 0;
    header[41] = 0;
    
    // Y pixels per meter
    header[42] = 0;
    header[43] = 0;
    header[44] = 0;
    header[45] = 0;
    
    // Colors used
    header[46] = 0;
    header[47] = 0;
    header[48] = 0;
    header[49] = 0;
    
    // Colors important
    header[50] = 0;
    header[51] = 0;
    header[52] = 0;
    header[53] = 0;
    
    return header;
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
        }
        
        .video-stream {
            display: block;
            max-width: 90vw;
            max-height: 70vh;
            width: auto;
            height: auto;
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
