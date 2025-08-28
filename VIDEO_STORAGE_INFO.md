# SafeRide AI - Video Storage Information

## 📹 Where Are Recorded Videos Saved?

### **Mobile Devices (Android/iOS):**

#### **Storage Location:**
- **Path**: `{App Documents Directory}/videos/`
- **File Format**: `.mp4`
- **Naming Pattern**: `saferide_recording_{timestamp}.mp4`

#### **Specific Locations:**

**Android:**
- Internal Storage: `/Android/data/com.example.saferide_ai_app/files/videos/`
- Or: `/storage/emulated/0/Android/data/com.example.saferide_ai_app/files/videos/`

**iOS:**
- App Sandbox: `{App Container}/Documents/videos/`
- Accessible through Files app under SafeRide AI

#### **Example File Names:**
```
saferide_recording_1692710123456.mp4
saferide_recording_1692710234567.mp4
saferide_recording_1692710345678.mp4
```

### **Web Browser:**

#### **Storage Method:**
- Videos are handled by the browser's download mechanism
- Files are downloaded to the user's default Downloads folder
- File naming: `saferide_recording_{timestamp}.webm` or browser default

#### **Browser-Specific Locations:**
- **Chrome**: `~/Downloads/`
- **Firefox**: `~/Downloads/`  
- **Safari**: `~/Downloads/`
- **Edge**: `~/Downloads/`

### **Features:**

#### **In-App Video Management:**
- ✅ View all recorded videos within the app
- ✅ Sort by date (newest first)
- ✅ Display file size and duration
- ✅ Delete videos directly from the app
- ✅ Share videos with other apps

#### **Video Quality:**
- **Resolution**: Optimized for ML Kit processing
- **Format**: MP4 (mobile) / WebM (web)
- **Frame Rate**: 30 FPS (mobile) / 15 FPS (web)

#### **Storage Management:**
- Videos are stored locally on the device
- No automatic cloud upload (for privacy)
- Users can manually share/backup videos
- Older videos can be deleted to free space

### **How to Access Your Videos:**

#### **Through the App:**
1. Login as User
2. Start Detection Mode  
3. Tap the "View Videos" button
4. Browse, play, or delete recordings

#### **Through File Manager:**
1. Open device File Manager
2. Navigate to `Android/data/com.example.saferide_ai_app/files/videos/`
3. Videos can be copied, moved, or shared

#### **Web Browser:**
1. Check your Downloads folder
2. Look for files starting with "saferide_recording_"
3. Videos can be played in any media player

### **Privacy & Security:**
- ✅ Videos are stored locally on your device
- ✅ No automatic cloud synchronization  
- ✅ User has full control over video retention
- ✅ Videos can be deleted at any time
- ✅ No third-party access without user permission

### **Troubleshooting:**

#### **Can't Find Videos?**
- Check app permissions for storage access
- Ensure sufficient storage space on device
- Try recording a test video first

#### **Videos Not Playing?**
- Ensure you have a compatible media player
- Check if the file was completely recorded
- Try a different video player app

#### **Storage Full?**
- Delete old recordings through the app
- Move important videos to external storage
- Clear app cache if needed
