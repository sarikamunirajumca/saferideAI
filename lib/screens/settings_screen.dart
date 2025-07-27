import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saferide_ai_app/services/detection_service.dart';
import 'package:saferide_ai_app/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text(
              'Detection Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Text('Configure what features to monitor'),
          ),
          
          _buildSwitchTile(
            title: 'Drowsiness Detection',
            subtitle: 'Detect when driver appears drowsy or sleepy',
            value: detectionService.isDrowsinessDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isDrowsinessDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Distraction Detection',
            subtitle: 'Detect when driver is not looking at the road',
            value: detectionService.isDistractionDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isDistractionDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Seatbelt Detection',
            subtitle: 'Detect if driver is wearing a seatbelt',
            value: detectionService.isSeatbeltDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isSeatbeltDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Yawning Detection',
            subtitle: 'Detect when driver is yawning frequently',
            value: detectionService.isYawningDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isYawningDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Passenger Monitoring',
            subtitle: 'Monitor passenger behavior and distractions',
            value: detectionService.isPassengerMonitoringEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isPassengerMonitoringEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Motion Sickness Detection',
            subtitle: 'Detect potential motion sickness in passengers',
            value: detectionService.isMotionSicknessDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isMotionSicknessDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Phone Usage Detection',
            subtitle: 'Detect when driver is using phone (experimental)',
            value: detectionService.isPhoneUsageDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isPhoneUsageDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Smoking Detection',
            subtitle: 'Detect smoking while driving (experimental)',
            value: detectionService.isSmokingDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isSmokingDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          _buildSwitchTile(
            title: 'Erratic Movement Detection',
            subtitle: 'Detect unusual head movement patterns',
            value: detectionService.isErraticMovementDetectionEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isErraticMovementDetectionEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          const Divider(),
          
          const ListTile(
            title: Text(
              'Alert Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Text('Configure how alerts are delivered'),
          ),
          
          _buildSwitchTile(
            title: 'Voice Alerts',
            subtitle: 'Enable spoken alerts for detected safety issues',
            value: detectionService.isVoiceAlertsEnabled,
            onChanged: (value) {
              setState(() {
                detectionService.isVoiceAlertsEnabled = value;
                detectionService.saveSettings();
              });
            },
          ),
          
          const Divider(),
          
          const ListTile(
            title: Text(
              'Recording Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Text('Configure video recording options'),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.blue,
                          size: 20.0,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Video Recording',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      'You can start and stop video recording from the monitoring screen when monitoring is active. Recorded videos are saved to your device storage.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      '• Start monitoring to enable recording controls\n• Videos are automatically saved with timestamps\n• Recordings continue until manually stopped',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const Divider(),
          
          const ListTile(
            title: Text(
              'Detection Statistics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Text('View alert counts for this session'),
          ),
          
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatRow('Drowsiness', detectionService.detectionStats.drowsinessDetections),
                  _buildStatRow('Distraction', detectionService.detectionStats.distractionDetections),
                  _buildStatRow('Seatbelt', detectionService.detectionStats.noSeatbeltDetections),
                  _buildStatRow('Yawning', detectionService.detectionStats.yawningDetections),
                  _buildStatRow('Passenger', detectionService.detectionStats.passengerDisturbanceDetections),
                  _buildStatRow('Motion Sickness', detectionService.detectionStats.motionSicknessDetections),
                  _buildStatRow('Phone Usage', detectionService.detectionStats.phoneUsageDetections),
                  _buildStatRow('Smoking', detectionService.detectionStats.smokingDetections),
                  _buildStatRow('Erratic Movement', detectionService.detectionStats.erraticMovementDetections),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      detectionService.resetStats();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reset Statistics'),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(),
          
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ),
          
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeColor: AppConstants.primaryColor,
      onChanged: onChanged,
    );
  }
  
  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label Alerts:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: count > 0 ? AppConstants.warningColor : Colors.green,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SafeRide AI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SafeRide AI is a vehicle monitoring application that uses '
              'computer vision and machine learning to detect and alert '
              'drivers about potential safety issues.',
            ),
            SizedBox(height: 16.0),
            Text(
              'Features include drowsiness detection, distraction monitoring, '
              'seatbelt detection, and passenger behavior analysis.',
            ),
            SizedBox(height: 16.0),
            Text(
              'Version: 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
