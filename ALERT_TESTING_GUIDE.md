# SafeRide AI - Alert Testing Guide

## How to Test the Detection Features

Your SafeRide AI app is now running with enhanced alerts! Here's how to test each detection feature:

### 🚨 **Alert System Features**
- **Visual Alerts**: Red banner with warning icon and message
- **Vibration Feedback**: 1-second phone vibration
- **Debug Logs**: Check console for alert messages

---

## 🧪 **Testing Each Detection Type**

### 1. **Drowsiness Detection** 
**How to trigger:** Close your eyes for 3-4 seconds while facing the camera
- **Threshold:** Eye Aspect Ratio < 0.23
- **Frames needed:** 15 consecutive frames (~1 second at 15 FPS)
- **Expected Alert:** "Driver appears drowsy! Please take a break!"
- **Cooldown:** 60 seconds between alerts

### 2. **Distraction Detection**
**How to trigger:** Turn your head significantly left, right, up, or down
- **Threshold:** Head rotation > 45 degrees from center
- **Frames needed:** 20 consecutive frames (~1.3 seconds)
- **Expected Alert:** "Driver distracted! Please focus on the road!"
- **Cooldown:** 30 seconds between alerts

### 3. **Yawning Detection**
**How to trigger:** Open your mouth wide (yawning motion)
- **Detection:** Based on mouth opening analysis
- **Expected Alert:** "Driver yawning detected! Consider taking a break!"
- **Cooldown:** 30 seconds between alerts

### 4. **Motion Sickness Detection**
**How to trigger:** Make erratic head movements for several seconds
- **Detection:** Analyzes head pose variations over time
- **Expected Alert:** "Motion sickness detected! Please check passenger comfort!"
- **Cooldown:** 30 seconds between alerts

---

## 🔧 **Troubleshooting Tips**

### If No Alerts Appear:
1. **Check App Status:** Ensure "Monitoring Active" is displayed
2. **Face Position:** Make sure your face is clearly visible and well-lit
3. **Detection Settings:** Go to Settings and ensure detection types are enabled
4. **Camera Permission:** Verify camera access is granted
5. **Debug Console:** Check VS Code debug console for "ALERT:" messages

### Current Detection Settings:
- ✅ Drowsiness Detection: Enabled
- ✅ Distraction Detection: Enabled  
- ✅ Yawning Detection: Enabled
- ✅ Erratic Movement Detection: Enabled
- ❌ Motion Sickness Detection: Disabled by default
- ❌ Phone Usage Detection: Disabled by default
- ❌ Smoking Detection: Disabled by default

### Alert Cooldowns Prevent Spam:
- Each alert type has a cooldown period to prevent continuous triggering
- If you just triggered an alert, wait for the cooldown period before testing again

---

## 📱 **Real-Time Monitoring**

While the app is running, you'll see:
- **Live camera feed** showing your face
- **Detection statistics** counting each type of detection
- **Red alert banner** when alerts are triggered
- **Vibration feedback** on your device
- **"Monitoring Active"** status indicator

---

## 🚗 **In-Car Installation Notes**

For actual in-car use:
- Mount device with camera facing driver
- Ensure good lighting conditions
- Position camera at driver's eye level
- Test all detection types before driving
- Adjust settings as needed for sensitivity

---

## 🐛 **Debug Information**

Check the VS Code console for detailed logs:
```
I/flutter: Camera initialized successfully
I/flutter: Detection service started
I/flutter: ALERT: Driver appears drowsy! Please take a break!
I/flutter: Vibration triggered
```

The app is now ready for comprehensive driver safety monitoring!
