import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saferide_ai_app/screens/monitoring_screen.dart';
import 'package:saferide_ai_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isFirstRun = true;
  
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }
  
  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstRun = prefs.getBool(PreferenceKeys.firstRun) ?? true;
    
    if (_isFirstRun) {
      _requestPermissions();
    } else {
      _navigateToMainScreen();
    }
  }
  
  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    
    // For iOS, we also need to request microphone permission for camera to work properly
    await Permission.microphone.request();
    
    if (cameraStatus.isGranted) {
      // Save first run preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PreferenceKeys.firstRun, false);
      
      _navigateToMainScreen();
    } else {
      // Show permission denied message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to use this app.'),
            duration: Duration(seconds: 3),
          ),
        );
        // Add a delay to show the snackbar before navigating
        Timer(const Duration(seconds: 3), () {
          _navigateToMainScreen();
        });
      }
    }
  }
  
  void _navigateToMainScreen() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MonitoringScreen(),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            const Icon(
              Icons.car_crash_outlined,
              size: 80.0,
              color: Colors.white,
            ),
            
            const SizedBox(height: 20.0),
            
            // App name
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10.0),
            
            // Tagline
            const Text(
              'Safer journeys with AI-powered monitoring',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40.0),
            
            // Loading spinner
            const SpinKitDoubleBounce(
              color: Colors.white,
              size: 50.0,
            ),
            
            const SizedBox(height: 20.0),
            
            // Status text
            Text(
              _isFirstRun ? 'Setting up...' : 'Loading...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
