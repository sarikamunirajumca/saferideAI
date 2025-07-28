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
      backgroundColor: AppConstants.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.backgroundDark,
              Color(0xFF1E3A8A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with modern styling
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 2.0,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 80.0,
                  color: AppConstants.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32.0),
              
              // App name with enhanced typography
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 12.0),
              
              // Tagline with better styling
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: const Text(
                  'Safer journeys with AI-powered monitoring',
                  style: TextStyle(
                    color: AppConstants.textSecondary,
                    fontSize: 16.0,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 64.0),
              
              // Modern loading indicator
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceDark,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20.0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const SpinKitDoubleBounce(
                  color: AppConstants.primaryColor,
                  size: 50.0,
                ),
              ),
              
              const SizedBox(height: 24.0),
              
              // Status text with enhanced styling
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  _isFirstRun ? 'Setting up permissions...' : 'Loading application...',
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
