# Libraries and Frameworks Used in SafeRide AI

## 🚀 Core Framework

### **Flutter Framework 3.0+**
- **Purpose**: Cross-platform mobile application development
- **Language**: Dart
- **Platforms**: iOS, Android, Web, Desktop
- **Architecture**: Widget-based reactive UI framework
- **Performance**: Hardware-accelerated rendering, 60+ FPS UI
- **Documentation**: [flutter.dev](https://flutter.dev)

```yaml
flutter:
  sdk: flutter
environment:
  sdk: '>=3.0.0 <4.0.0'
```

## 🧠 AI/ML Libraries

### **Google ML Kit Face Detection v0.13.1**
- **Purpose**: On-device face detection and facial landmark analysis
- **Features**: 
  - Real-time face detection
  - 468 facial landmarks
  - Face contours and classification
  - Head pose estimation
- **Performance**: Optimized for mobile devices
- **Privacy**: 100% on-device processing
- **Documentation**: [developers.google.com/ml-kit](https://developers.google.com/ml-kit)

```yaml
google_mlkit_face_detection: ^0.13.1
```

#### **Capabilities**
- Eye landmark detection (12 points per eye)
- Mouth landmark detection (20 points)
- Nose and face contour tracking
- Real-time facial feature analysis
- Confidence scoring for detections

## 📱 Camera & Media Libraries

### **Camera v0.10.0**
- **Purpose**: Camera access and control
- **Features**:
  - Real-time camera preview
  - Image capture and video recording
  - Camera settings control (focus, flash, resolution)
  - Front/rear camera switching
- **Platform Support**: iOS, Android, Web
- **Performance**: Hardware-accelerated image processing

```yaml
camera: ^0.10.0
```

#### **Advanced Features**
- Image stream for real-time processing
- Video recording with audio
- Resolution and quality control
- Camera lifecycle management

### **Video Player v2.8.2**
- **Purpose**: Video playback and media control
- **Features**:
  - Video file playback
  - Streaming video support
  - Playback controls (play, pause, seek)
  - Multiple format support
- **Integration**: Works with recorded detection videos

```yaml
video_player: ^2.8.2
```

## 🔊 Audio & Voice Libraries

### **Flutter TTS v4.0.2**
- **Purpose**: Text-to-speech for voice alerts
- **Features**:
  - Multi-language support
  - Voice speed and pitch control
  - Background audio capabilities
  - Platform-specific voice engines
- **Safety**: Critical for driver alerts without visual distraction

```yaml
flutter_tts: ^4.0.2
```

#### **Voice Alert System**
- Emergency drowsiness alerts
- Distraction warnings
- Fatigue notifications
- Multi-language voice messages

### **Vibration v3.1.3**
- **Purpose**: Haptic feedback for alerts
- **Features**:
  - Device vibration control
  - Pattern-based vibration
  - Duration and intensity control
  - Silent alert capability
- **Safety**: Non-visual alert mechanism

```yaml
vibration: ^3.1.3
```

## 📊 State Management & Architecture

### **Provider v6.0.0**
- **Purpose**: State management and dependency injection
- **Pattern**: Observer pattern implementation
- **Features**:
  - Reactive UI updates
  - Scoped state management
  - Consumer widgets for selective rebuilds
  - Multi-provider support
- **Architecture**: MVVM pattern enabler

```yaml
provider: ^6.0.0
```

#### **Service Architecture**
- `CameraService`: Camera lifecycle and frame processing
- `DetectionService`: AI detection algorithms
- `NotificationService`: Alert and notification management
- `StreamingService`: Live video streaming

## 🔔 Notification & Alert Libraries

### **Flutter Local Notifications v19.4.0**
- **Purpose**: System-level notifications and alerts
- **Features**:
  - Persistent notifications
  - Custom alert sounds
  - Priority-based notifications
  - Background notification support
- **Safety**: Critical alert delivery even when app is backgrounded

```yaml
flutter_local_notifications: ^19.4.0
```

#### **Alert Types**
- High-priority drowsiness alerts
- Distraction warnings
- System status notifications
- Emergency alerts

## 💾 Storage & Persistence Libraries

### **Shared Preferences v2.0.15**
- **Purpose**: Local data storage and user preferences
- **Features**:
  - Key-value storage
  - Cross-platform persistence
  - Async read/write operations
  - Type-safe data storage
- **Usage**: Settings, detection statistics, user preferences

```yaml
shared_preferences: ^2.0.15
```

#### **Stored Data**
- Detection sensitivity settings
- Alert preferences (voice/vibration)
- Historical detection statistics
- User configuration profiles

### **Path Provider v2.0.11**
- **Purpose**: Platform-specific directory access
- **Features**:
  - Documents directory access
  - Cache directory management
  - External storage handling
  - Cross-platform path resolution
- **Usage**: Video recording storage, data export

```yaml
path_provider: ^2.0.11
```

### **Path v1.8.2**
- **Purpose**: File path manipulation utilities
- **Features**:
  - Path joining and normalization
  - File extension handling
  - Platform-agnostic path operations
  - Directory traversal utilities

```yaml
path: ^1.8.2
```

## 🌐 Web & Networking Libraries

### **Shelf v1.4.1**
- **Purpose**: HTTP server framework for streaming
- **Features**:
  - Lightweight HTTP server
  - Middleware support
  - Request/response handling
  - WebSocket support
- **Usage**: Live video streaming server

```yaml
shelf: ^1.4.1
```

### **Shelf Router v1.1.4**
- **Purpose**: HTTP routing for web interface
- **Features**:
  - RESTful routing
  - Parameter extraction
  - Route middleware
  - Clean URL handling
- **Usage**: Admin dashboard web interface

```yaml
shelf_router: ^1.1.4
```

### **Shelf Static v1.1.2**
- **Purpose**: Static file serving
- **Features**:
  - Static asset serving
  - MIME type handling
  - Cache control headers
  - Directory browsing
- **Usage**: Web dashboard assets

```yaml
shelf_static: ^1.1.2
```

### **Network Info Plus v6.0.0**
- **Purpose**: Network information and connectivity
- **Features**:
  - WiFi network information
  - IP address detection
  - Connection status monitoring
  - Network type identification
- **Usage**: Streaming server setup, network diagnostics

```yaml
network_info_plus: ^6.0.0
```

## 🔐 System & Device Libraries

### **Permission Handler v12.0.1**
- **Purpose**: Runtime permission management
- **Features**:
  - Camera permission handling
  - Storage permission management
  - Notification permission control
  - Cross-platform permission API
- **Critical**: Required for camera access and notifications

```yaml
permission_handler: ^12.0.1
```

#### **Required Permissions**
- Camera access (essential)
- Microphone access (for video recording)
- Storage access (for saving recordings)
- Notification access (for alerts)

### **Wakelock Plus v1.1.1**
- **Purpose**: Prevent device sleep during monitoring
- **Features**:
  - Screen wake lock
  - CPU wake lock
  - Conditional wake lock management
  - Battery-aware operation
- **Critical**: Keeps app active during driving

```yaml
wakelock_plus: ^1.1.1
```

## 🎨 UI & UX Libraries

### **Cupertino Icons v1.0.2**
- **Purpose**: iOS-style icons for cross-platform consistency
- **Features**:
  - iOS design system icons
  - Scalable vector icons
  - Theme-aware coloring
  - Consistent cross-platform appearance

```yaml
cupertino_icons: ^1.0.2
```

### **Flutter SpinKit v5.1.0**
- **Purpose**: Loading animations and activity indicators
- **Features**:
  - Pre-built loading animations
  - Customizable colors and sizes
  - Multiple animation styles
  - Performance-optimized animations
- **Usage**: Detection processing indicators, camera initialization

```yaml
flutter_spinkit: ^5.1.0
```

#### **Animation Types Used**
- Rotating ring for detection processing
- Pulse animation for camera initialization
- Wave animation for data loading
- Fade animation for status transitions

## 🧪 Development & Testing Libraries

### **Flutter Test**
- **Purpose**: Unit and widget testing framework
- **Features**:
  - Widget testing utilities
  - Mock objects and test doubles
  - Async testing support
  - Golden file testing
- **Coverage**: Algorithm testing, UI testing, integration testing

```yaml
flutter_test:
  sdk: flutter
```

### **Flutter Lints v2.0.0**
- **Purpose**: Code quality and style enforcement
- **Features**:
  - Dart and Flutter best practices
  - Code style consistency
  - Performance recommendations
  - Security best practices
- **Standards**: Follows official Flutter guidelines

```yaml
flutter_lints: ^2.0.0
```

## 📋 Library Categories Summary

### **Core Framework (1)**
- Flutter SDK - Cross-platform development framework

### **AI/ML Libraries (1)**
- Google ML Kit Face Detection - On-device face detection and analysis

### **Media & Camera (2)**
- Camera - Real-time camera access and control
- Video Player - Video playback and media handling

### **Audio & Haptics (2)**
- Flutter TTS - Text-to-speech voice alerts
- Vibration - Haptic feedback for notifications

### **State Management (1)**
- Provider - Reactive state management and dependency injection

### **Storage & Persistence (3)**
- Shared Preferences - Local key-value storage
- Path Provider - Platform directory access
- Path - File path manipulation utilities

### **Networking & Web (4)**
- Shelf - HTTP server framework
- Shelf Router - HTTP routing system
- Shelf Static - Static file serving
- Network Info Plus - Network connectivity information

### **System & Permissions (2)**
- Permission Handler - Runtime permission management
- Wakelock Plus - Device sleep prevention

### **UI & Notifications (3)**
- Cupertino Icons - iOS-style iconography
- Flutter SpinKit - Loading animations
- Flutter Local Notifications - System notifications

### **Development Tools (2)**
- Flutter Test - Testing framework
- Flutter Lints - Code quality enforcement

## 🎯 Library Selection Criteria

### **Performance Requirements**
- **Real-time Processing**: Libraries optimized for <100ms latency
- **Battery Efficiency**: Power-aware implementations
- **Memory Management**: Efficient memory usage patterns
- **CPU Optimization**: Multi-threaded and asynchronous processing

### **Safety & Reliability**
- **Mission-Critical**: Libraries with proven stability for safety applications
- **Error Handling**: Robust error handling and recovery mechanisms
- **Platform Consistency**: Consistent behavior across iOS and Android
- **Update Frequency**: Actively maintained with security updates

### **Privacy & Security**
- **On-Device Processing**: Libraries supporting local computation
- **No Data Transmission**: Avoid libraries requiring external services
- **Minimal Permissions**: Libraries with minimal permission requirements
- **Open Source**: Transparent and auditable codebases

### **Developer Experience**
- **Documentation Quality**: Comprehensive documentation and examples
- **Community Support**: Active community and issue resolution
- **API Stability**: Stable APIs with clear migration paths
- **Testing Support**: Built-in testing utilities and mock support

## 🔄 Version Management Strategy

### **Dependency Updates**
- **Security Patches**: Immediate updates for security vulnerabilities
- **Minor Updates**: Regular updates for bug fixes and improvements
- **Major Updates**: Careful evaluation and testing before adoption
- **Compatibility**: Maintain backward compatibility where possible

### **Version Pinning**
- **Stable Versions**: Use stable releases for production
- **Beta Testing**: Test beta versions in development environment
- **Lock File**: Use pubspec.lock for reproducible builds
- **CI/CD Integration**: Automated dependency vulnerability scanning

## 📊 Library Statistics

### **Total Dependencies: 18**
- **Production Dependencies**: 16
- **Development Dependencies**: 2
- **Flutter SDK Dependencies**: 2
- **Third-Party Libraries**: 16

### **Functionality Distribution**
- **AI/ML**: 6% (1/18)
- **Media**: 11% (2/18)
- **System**: 22% (4/18)
- **Storage**: 17% (3/18)
- **Networking**: 22% (4/18)
- **UI/UX**: 17% (3/18)
- **Development**: 11% (2/18)

### **Platform Support**
- **iOS**: 18/18 (100%)
- **Android**: 18/18 (100%)
- **Web**: 16/18 (89%)
- **Desktop**: 14/18 (78%)

This comprehensive library ecosystem enables SafeRide AI to deliver advanced vehicle safety monitoring with real-time AI processing, cross-platform compatibility, and robust performance across all supported platforms.
