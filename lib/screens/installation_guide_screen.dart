import 'package:flutter/material.dart';
import 'package:saferide_ai_app/utils/constants.dart';

class InstallationGuideScreen extends StatelessWidget {
  const InstallationGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-Car Installation Guide'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 40.0,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 16.0),
                  const Expanded(
                    child: Text(
                      'Transform your car into a smart safety monitoring system',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24.0),
            
            // Installation Steps
            _buildSectionTitle('📱 Device Mounting'),
            _buildInstallationStep(
              '1. Choose Mounting Position',
              'Mount your device on the dashboard or windshield where it can clearly see the driver\'s face. Ensure the front-facing camera has an unobstructed view.',
              Icons.place,
            ),
            
            _buildInstallationStep(
              '2. Secure Power Connection',
              'Connect your device to a reliable power source using a car charger or hardwired USB connection to ensure continuous operation.',
              Icons.power,
            ),
            
            _buildInstallationStep(
              '3. Optimize Camera Angle',
              'Adjust the device angle so the camera captures the driver\'s face clearly. The optimal range is 2-4 feet from the driver.',
              Icons.camera_alt,
            ),
            
            const SizedBox(height: 24.0),
            
            _buildSectionTitle('⚙️ Configuration'),
            _buildInstallationStep(
              '4. Enable Detection Features',
              'Go to Settings and enable the detection features you want: drowsiness, distraction, yawning, motion sickness, and erratic movement detection.',
              Icons.settings,
            ),
            
            _buildInstallationStep(
              '5. Adjust Sensitivity',
              'Fine-tune detection thresholds based on your driving environment and personal preferences.',
              Icons.tune,
            ),
            
            _buildInstallationStep(
              '6. Test All Features',
              'Run a test session to ensure all features are working correctly and alerts are audible.',
              Icons.play_circle,
            ),
            
            const SizedBox(height: 24.0),
            
            _buildSectionTitle('🚗 In-Car Integration Features'),
            
            // Feature Cards
            _buildFeatureCard(
              'Advanced Drowsiness Detection',
              'Uses Eye Aspect Ratio (EAR) analysis with windowed detection for accurate sleep detection',
              Icons.visibility_off,
              AppConstants.dangerColor,
            ),
            
            _buildFeatureCard(
              'Head Pose Monitoring',
              'Tracks head rotation angles to detect driver distraction and erratic movements',
              Icons.face,
              AppConstants.warningColor,
            ),
            
            _buildFeatureCard(
              'Motion Sickness Detection',
              'Analyzes head movement patterns to detect passenger motion sickness',
              Icons.sick,
              AppConstants.primaryColor,
            ),
            
            _buildFeatureCard(
              'Yawning Analysis',
              'Uses Mouth Aspect Ratio (MAR) calculation for fatigue detection',
              Icons.sentiment_very_dissatisfied,
              Colors.orange,
            ),
            
            _buildFeatureCard(
              'Priority Alert System',
              'Intelligent alert prioritization prevents alert spam and ensures critical alerts are heard',
              Icons.priority_high,
              AppConstants.successColor,
            ),
            
            const SizedBox(height: 24.0),
            
            _buildSectionTitle('🔧 Technical Specifications'),
            
            _buildTechnicalSpec('Processing', 'Real-time AI analysis at 15 FPS'),
            _buildTechnicalSpec('Privacy', 'All processing done on-device, no data uploaded'),
            _buildTechnicalSpec('Battery', 'Optimized for continuous car usage'),
            _buildTechnicalSpec('Compatibility', 'Works with front-facing camera'),
            _buildTechnicalSpec('Storage', 'Optional image capture for analysis'),
            
            const SizedBox(height: 24.0),
            
            // Safety Notice
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppConstants.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppConstants.warningColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppConstants.warningColor,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Text(
                      'Important: This system is designed to assist, not replace, safe driving practices. Always remain alert and follow traffic laws.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32.0),
            
            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: const Text(
                  'Start Monitoring',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildInstallationStep(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechnicalSpec(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100.0,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
