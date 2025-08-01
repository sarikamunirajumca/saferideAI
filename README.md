# SafeRide AI App - Advanced In-Car Safety Monitoring System

SafeRide AI App is a comprehensive Flutter-based mobile application that transforms your smartphone or tablet into an intelligent in-car safety monitoring system. By integrating advanced computer vision algorithms from our car_ai Python system, this app provides real-time driver and passenger safety monitoring with sophisticated AI-powered detection capabilities.

## 🎯 **Purpose**
Transform any vehicle into a smart safety monitoring system by installing a device running SafeRide AI App on the dashboard. The app continuously monitors driver behavior and passenger safety, providing immediate alerts for potentially dangerous situations.

## 🚗 **In-Car Installation**
- **Dashboard Mounting**: Secure device on dashboard with clear view of driver
- **Power Connection**: Connect to car's power system for continuous operation  
- **Camera Positioning**: Front-facing camera positioned 2-4 feet from driver
- **Always-On Operation**: Designed for continuous in-car use

## 🧠 **Advanced Detection Features**

### **Drowsiness Detection (Enhanced from car_ai)**
- **Eye Aspect Ratio (EAR) Analysis**: Real-time eye closure monitoring
- **Windowed Detection**: Analyzes patterns over 2.5-second windows
- **Sleep Ratio Calculation**: Detects when 80% of frames show closed eyes
- **Configurable Sensitivity**: Adjustable thresholds for different conditions

### **Driver Distraction Monitoring**
- **Head Pose Estimation**: 3D head tracking using facial landmarks
- **Angle Thresholds**: Alerts when head turns beyond 45° (looking away)
- **Continuous Tracking**: Real-time head position monitoring
- **Multi-axis Analysis**: Pitch, yaw, and roll angle detection

### **Advanced Yawning Detection**
- **Mouth Aspect Ratio (MAR)**: Sophisticated mouth opening analysis
- **Fatigue Correlation**: Links yawning frequency to tiredness levels
- **Temporal Analysis**: Tracks yawning patterns over time
- **Early Warning System**: Detects fatigue before severe drowsiness

### **Motion Sickness Detection**
- **Head Movement Analysis**: Tracks 30-frame history of head positions
- **Statistical Analysis**: Calculates standard deviation of movement
- **Erratic Pattern Detection**: Identifies unusual head movement patterns
- **Passenger Monitoring**: Extends beyond just driver monitoring

### **Priority-Based Alert System**
1. **Sleep/Drowsiness** (Highest Priority - 60s cooldown)
2. **Driver Distraction** (High Priority - 30s cooldown)
3. **Phone Usage** (Medium Priority - experimental)
4. **Smoking Detection** (Medium Priority - experimental)
5. **Seatbelt Monitoring** (Medium Priority)
6. **Yawning/Fatigue** (Lower Priority - 30s cooldown)
7. **Motion Sickness** (Lowest Priority - 30s cooldown)

## 📱 **Technical Architecture**

### **Flutter Framework**
- **Cross-Platform**: Runs on both Android and iOS
- **Real-Time Processing**: 15 FPS analysis for optimal performance
- **State Management**: Provider pattern for reactive UI updates
- **Persistent Storage**: Settings and statistics saved locally

### **AI/ML Integration**
- **Google ML Kit**: Face detection and facial landmark analysis
- **On-Device Processing**: All AI computation happens locally
- **Privacy-First**: No data uploaded to external servers
- **Real-Time Analysis**: Immediate processing and alert generation

### **Advanced Algorithms (From car_ai)**
```dart
// Eye Aspect Ratio (EAR) Calculation
final ear = (leftEyeOpen + rightEyeOpen) / 2.0;

// Windowed Sleep Detection
final sleepRatio = closedEyeFrames / totalFrames;

// Head Pose Analysis
final distraction = abs(headYaw) > 45° || abs(headPitch) > 45°;

// Motion Sickness Detection
final movementStd = calculateStandardDeviation(headPoseHistory);
```

## 🔧 **Configuration Options**

### **Detection Toggles**
- ✅ Drowsiness Detection (Default: ON)
- ✅ Distraction Detection (Default: ON) 
- ✅ Yawning Detection (Default: ON)
- ✅ Motion Sickness Detection (Default: OFF)
- ✅ Erratic Movement Detection (Default: ON)
- 🧪 Phone Usage Detection (Experimental)
- 🧪 Smoking Detection (Experimental)

### **Sensitivity Settings**
- **Eye Closure Threshold**: 0.23 (from car_ai optimization)
- **Head Pose Threshold**: 45° (distraction detection)
- **MAR Threshold**: 0.7 (yawning detection)
- **Motion Threshold**: 8.0 (erratic movement)
- **Window Size**: 37 frames (2.5 seconds at 15 FPS)

## 🚨 **Alert System**

### **Multi-Modal Alerts**
- **Visual**: On-screen notifications and indicators
- **Audio**: Voice alerts with priority-based messaging
- **Haptic**: Vibration feedback (configurable)
- **System**: OS-level persistent notifications

### **Smart Cooldown System**
- Prevents alert spam with intelligent timing
- Different cooldown periods for different alert types
- Priority override for critical situations
- Configurable alert delays

## 📊 **Statistics & Analytics**

### **Real-Time Monitoring**
- Live detection counters for each alert type
- Historical detection data with timestamps
- Confidence scores for each detection
- Session-based statistics tracking

### **Data Export**
- JSON format statistics export
- Detection history with timestamps
- Configurable data retention periods
- Privacy-compliant local storage

## 🔋 **Power & Performance**

### **Optimized for Continuous Use**
- **Battery Management**: Efficient processing algorithms
- **Thermal Control**: Frame rate adjustment for heat management
- **Memory Optimization**: Circular buffers for history data
- **Wake Lock**: Keeps screen active during monitoring

### **Hardware Requirements**
- **Camera**: Front-facing camera with decent quality
- **Processor**: Modern smartphone/tablet (last 5 years)
- **RAM**: 3GB minimum for smooth operation
- **Storage**: 100MB for app + detection data
- **Power**: Continuous power connection recommended

## 🛡️ **Privacy & Security**

### **Local Processing Only**
- All AI analysis performed on-device
- No network connectivity required for core features
- No personal data transmitted to external servers
- User controls all data retention and deletion

### **Optional Features**
- Image capture for detection analysis (user controlled)
- Statistics sharing (opt-in only)
- Cloud backup of settings (encrypted, optional)

## 🚀 **Installation Guide**

### **Device Setup**
1. Install SafeRide AI App from app store
2. Grant camera and notification permissions
3. Complete initial configuration wizard
4. Test all detection features

### **Vehicle Integration**
1. **Mount Device**: Secure mounting on dashboard
2. **Power Connection**: USB charging or hardwired power
3. **Camera Positioning**: Optimal angle for driver monitoring
4. **Testing**: Verify all features work in driving position

### **Calibration**
1. Adjust detection sensitivity based on vehicle
2. Configure alert preferences
3. Test emergency alert functionality
4. Set up automatic startup

## 📈 **Benefits**

### **For Drivers**
- **Accident Prevention**: Early warning of dangerous states
- **Fatigue Management**: Objective tiredness detection
- **Attention Monitoring**: Distraction awareness
- **Health Monitoring**: Motion sickness and stress detection

### **For Fleet Management**
- **Driver Safety Scoring**: Objective safety metrics
- **Incident Prevention**: Proactive safety measures
- **Compliance Monitoring**: Safety regulation adherence
- **Insurance Benefits**: Potential premium reductions

### **For Families**
- **Teen Driver Monitoring**: Supervise young drivers
- **Elderly Care**: Additional safety for senior drivers
- **Medical Conditions**: Monitor drivers with health issues
- **Long Trip Safety**: Extended journey monitoring

## 🔮 **Future Enhancements**

### **Planned Features**
- **Advanced Object Detection**: Enhanced phone/smoking detection
- **Biometric Integration**: Heart rate and stress monitoring
- **Weather Adaptation**: Detection adjustment for conditions
- **Machine Learning**: Personalized threshold learning

### **Integration Possibilities**
- **Vehicle Systems**: OBD-II port integration
- **Cloud Analytics**: Optional fleet management features
- **Wearable Devices**: Smartwatch companion app
- **Emergency Services**: Automatic incident reporting

## 🆚 **Advantages Over Traditional Systems**

### **Cost-Effective**
- Use existing smartphone/tablet hardware
- No expensive dedicated monitoring equipment
- Easy installation and setup
- Upgradeable through software updates

### **Advanced Algorithms**
- State-of-the-art computer vision techniques
- Continuously improving detection accuracy
- Multi-modal analysis for comprehensive monitoring
- Learned from extensive car_ai research and development

### **Flexibility**
- Works in any vehicle with mounting solution
- Transferable between vehicles
- Customizable for different use cases
- Regular feature updates and improvements

SafeRide AI App represents the next generation of vehicle safety technology, bringing advanced laboratory-grade detection algorithms into practical, everyday use for enhanced road safety and driver awareness.

## 🔧 **Development Setup**

### **Prerequisites**
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Physical device (camera access required for testing)

### **Installation Steps**
1. **Clone the repository**
   ```bash
   git clone https://github.com/sarikamunirajumca/saferide-ai-app.git
   cd saferide_ai_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### **Key Dependencies**
- **camera**: ^0.10.0 - Camera access and controls
- **google_mlkit_face_detection**: ^0.13.1 - AI-powered face detection
- **provider**: ^6.0.0 - State management
- **wakelock_plus**: ^1.1.1 - Keep screen active during monitoring
- **flutter_tts**: ^4.0.2 - Text-to-speech for voice alerts
- **flutter_local_notifications**: ^19.4.0 - System notifications
- **vibration**: ^3.1.3 - Haptic feedback

## 📱 **App Architecture**

### **Core Services**
- **CameraService**: Manages camera lifecycle and frame capture
- **DetectionService**: Implements AI detection algorithms from car_ai
- **NotificationService**: Handles alerts and notifications
- **StreamingService**: Real-time video streaming capabilities
- **WebDetectionService**: Optional web interface for monitoring

### **Screen Structure**
- **SplashScreen**: App initialization and permissions
- **MonitoringScreen**: Main detection interface with real-time analysis
- **SettingsScreen**: Configuration and sensitivity adjustments
- **InstallationGuideScreen**: Step-by-step vehicle setup instructions

### **Real-Time Detection Pipeline**
```
Camera Frame → Face Detection → Landmark Analysis → 
Feature Extraction → Algorithm Processing → Alert Decision → 
UI Update + Voice Alert + Notification
```

## 📊 **Detection Algorithms Implementation**

### **From car_ai Python Integration**
The Flutter app implements the same sophisticated algorithms from the car_ai Python system:

#### **Drowsiness Detection**
```dart
// Eye Aspect Ratio (EAR) calculation
double calculateEAR(List<FaceLandmark> landmarks) {
  final leftEye = getEyeLandmarks(landmarks, isLeft: true);
  final rightEye = getEyeLandmarks(landmarks, isLeft: false);
  return (calculateEyeAspectRatio(leftEye) + calculateEyeAspectRatio(rightEye)) / 2.0;
}

// Windowed sleep detection (2.5 second window)
bool detectDrowsiness(List<double> earHistory) {
  final threshold = 0.23; // Same as car_ai
  final sleepRatio = earHistory.where((ear) => ear < threshold).length / earHistory.length;
  return sleepRatio > 0.8;
}
```

#### **Head Pose Analysis**
```dart
// 3D head pose estimation for distraction detection
class HeadPose {
  final double pitch;
  final double yaw;
  final double roll;
  
  bool get isDistracted => yaw.abs() > 45 || pitch.abs() > 45;
}
```

#### **Motion Sickness Detection**
```dart
// Statistical analysis of head movement patterns
bool detectMotionSickness(List<HeadPose> poseHistory) {
  final movements = calculateMovementStandardDeviation(poseHistory);
  return movements.any((std) => std > 8.0);
}
```

## 🔄 **Real-Time Streaming Features**

### **MJPEG Streaming Server**
- Built-in HTTP server for remote monitoring
- Real-time video stream with detection overlays
- Web interface accessible via local network
- Configurable streaming quality and frame rate

### **Network Integration**
```dart
// Start streaming server
final streamingService = StreamingService();
await streamingService.startServer(port: 8080);

// Access via: http://[device-ip]:8080/stream
```

## ⚙️ **Configuration Management**

### **Persistent Settings**
- Detection sensitivity thresholds
- Alert cooldown periods
- Audio/visual/haptic preferences
- Historical data retention settings
- Streaming configuration

### **Adaptive Algorithms**
- Automatic threshold adjustment based on lighting
- User behavior learning for reduced false positives
- Environmental adaptation for different vehicles
- Calibration wizard for optimal setup

## 🚨 **Advanced Alert System**

### **Multi-Level Priority System**
1. **CRITICAL** - Sleep/Unconsciousness (Immediate alert)
2. **HIGH** - Severe distraction (30s cooldown)
3. **MEDIUM** - Phone usage, yawning (60s cooldown)
4. **LOW** - Motion patterns, minor distractions (120s cooldown)

### **Smart Alert Management**
- Context-aware alert timing
- Escalating alert intensity
- Emergency override capabilities
- Silent mode for passenger monitoring

## 📈 **Performance Optimization**

### **Battery & Thermal Management**
- Adaptive frame rate (5-30 FPS based on conditions)
- GPU acceleration for ML processing
- Background processing optimization
- Intelligent resource allocation

### **Memory Management**
- Circular buffers for historical data
- Efficient face landmark caching
- Automatic garbage collection
- Memory leak prevention

## 🛡️ **Security & Privacy**

### **Data Protection**
- 100% on-device processing
- No cloud data transmission
- Encrypted local storage
- User-controlled data retention

### **Permissions Management**
- Camera access (required)
- Notification permissions (required)
- Storage access (optional)
- Location services (disabled by default)

## 🔮 **Roadmap & Future Enhancements**

### **Version 2.0 Planned Features**
- **Advanced Object Detection**: Enhanced phone/smoking detection
- **Biometric Integration**: Heart rate monitoring via camera
- **Fleet Management**: Multi-device coordination
- **Cloud Analytics**: Optional aggregate safety insights

### **Integration Possibilities**
- **Android Auto/Apple CarPlay**: Native vehicle integration
- **OBD-II Port**: Vehicle diagnostic data correlation
- **Smartwatch Companion**: Additional biometric monitoring
- **Emergency Services**: Automatic incident reporting

## 📞 **Support & Contributing**

### **Bug Reports & Feature Requests**
- GitHub Issues: [Report bugs or request features](https://github.com/sarikamunirajumca/saferide-ai-app/issues)
- Email Support: sarikamunirajumca@example.com

### **Contributing Guidelines**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Development Resources**
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google ML Kit Documentation](https://developers.google.com/ml-kit)
- [Car AI Python System](https://github.com/sarikamunirajumca/car-ai) - Backend algorithms

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Flutter Team** - Excellent cross-platform framework
- **Google ML Kit** - On-device machine learning capabilities
- **Car AI Python Project** - Core detection algorithms and research
- **Open Source Community** - Various libraries and contributions

---

**⚠️ Safety Disclaimer**: SafeRide AI App is designed to assist with safety monitoring but should not be considered a replacement for attentive and responsible driving. Always follow traffic laws, maintain focus while driving, and use this technology as a supplementary safety tool only. The developers are not responsible for any accidents or incidents that may occur while using this application.
