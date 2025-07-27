import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:saferide_ai_app/utils/constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() => _instance;
  
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    debugPrint('Notification service initialized');
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap action
  }
  
  Future<void> showDrowsinessAlert() async {
    debugPrint('Showing drowsiness alert');
    _showAlert(
      id: 1,
      title: 'Drowsiness Detected',
      body: 'Wake up! You appear to be drowsy.',
      payload: 'drowsiness',
    );
  }
  
  Future<void> showDistractionAlert() async {
    debugPrint('Showing distraction alert');
    _showAlert(
      id: 2,
      title: 'Distraction Detected',
      body: 'Keep your eyes on the road!',
      payload: 'distraction',
    );
  }
  
  Future<void> showSeatbeltAlert() async {
    debugPrint('Showing seatbelt alert');
    _showAlert(
      id: 3,
      title: 'Seatbelt Not Detected',
      body: 'Please fasten your seatbelt for safety.',
      payload: 'seatbelt',
    );
  }
  
  Future<void> showYawningAlert() async {
    debugPrint('Showing yawning alert');
    _showAlert(
      id: 4,
      title: 'Yawning Detected',
      body: 'You seem tired. Consider taking a break.',
      payload: 'yawning',
    );
  }
  
  Future<void> showPassengerDisturbanceAlert() async {
    debugPrint('Showing passenger disturbance alert');
    _showAlert(
      id: 5,
      title: 'Passenger Disturbance',
      body: 'Passenger activity detected. Stay focused.',
      payload: 'passenger',
    );
  }
  
  Future<void> showMotionSicknessAlert() async {
    debugPrint('Showing motion sickness alert');
    _showAlert(
      id: 6,
      title: 'Motion Sickness Risk',
      body: 'Passenger may be experiencing motion sickness.',
      payload: 'motionsickness',
    );
  }
  
  Future<void> showPhoneUsageAlert() async {
    debugPrint('Showing phone usage alert');
    _showAlert(
      id: 7,
      title: 'Phone Usage Detected',
      body: 'Please put away your phone and focus on driving.',
      payload: 'phoneusage',
    );
  }
  
  Future<void> showSmokingAlert() async {
    debugPrint('Showing smoking alert');
    _showAlert(
      id: 8,
      title: 'Smoking Detected',
      body: 'Smoking while driving can be dangerous.',
      payload: 'smoking',
    );
  }
  
  Future<void> showErraticMovementAlert() async {
    debugPrint('Showing erratic movement alert');
    _showAlert(
      id: 9,
      title: 'Erratic Movement Detected',
      body: 'Unusual head movement patterns detected.',
      payload: 'erraticmovement',
    );
  }
  
  Future<void> _showAlert({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'driver_monitoring',
      'Driver Monitoring',
      channelDescription: 'Alerts for driver monitoring',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'SafeRide AI Alert',
      color: AppConstants.dangerColor,
      enableLights: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
