import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/driver_profile_service.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      relationship: json['relationship'],
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}

class EmergencyService {
  static bool _sosActive = false;
  static Timer? _sosTimer;
  static List<EmergencyContact> _emergencyContacts = [];

  static bool get isSosActive => _sosActive;

  static Future<void> triggerSOS({
    required String location,
    required String driverName,
    String additionalInfo = '',
  }) async {
    if (_sosActive) return;

    _sosActive = true;
    
    // Send alerts to emergency contacts
    for (final contact in _emergencyContacts) {
      await _sendEmergencyAlert(
        contact: contact,
        location: location,
        driverName: driverName,
        additionalInfo: additionalInfo,
      );
    }

    // Auto-deactivate SOS after 5 minutes
    _sosTimer = Timer(const Duration(minutes: 5), () {
      _sosActive = false;
    });
  }

  static Future<void> _sendEmergencyAlert({
    required EmergencyContact contact,
    required String location,
    required String driverName,
    required String additionalInfo,
  }) async {
    final message = 'EMERGENCY ALERT: $driverName may need assistance. '
        'Location: $location. '
        'Time: ${DateTime.now().toString()}. '
        '$additionalInfo '
        'This is an automated message from SafeRide AI.';

    try {
      // Try to send SMS
      final smsUri = Uri.parse('sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('Failed to send SMS: $e');
    }
  }

  static Future<void> callEmergencyContact(EmergencyContact contact) async {
    final phoneUri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  static void cancelSOS() {
    _sosActive = false;
    _sosTimer?.cancel();
  }

  static void setEmergencyContacts(List<EmergencyContact> contacts) {
    _emergencyContacts = contacts;
  }
}

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  List<EmergencyContact> _contacts = [];
  bool _sosCountdown = false;
  int _countdownSeconds = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    // Load from driver profile or shared preferences
    // For now, using sample data
    setState(() {
      _contacts = [
        EmergencyContact(
          id: '1',
          name: 'John Doe',
          phoneNumber: '+1234567890',
          relationship: 'Spouse',
          isPrimary: true,
        ),
        EmergencyContact(
          id: '2',
          name: 'Jane Smith',
          phoneNumber: '+0987654321',
          relationship: 'Emergency Contact',
        ),
      ];
    });
    EmergencyService.setEmergencyContacts(_contacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergency'),
        backgroundColor: Colors.red[700],
      ),
      body: _sosCountdown ? _buildSOSCountdown() : _buildEmergencyScreen(),
    );
  }

  Widget _buildEmergencyScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // SOS Button
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.red[300]!, Colors.red[700]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _startSOSCountdown,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emergency,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Tap for Emergency',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Emergency Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📞 Emergency Contacts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_contacts.isEmpty)
                    const Text('No emergency contacts added yet.')
                  else
                    ..._contacts.map(_buildContactTile),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddContactDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Contact'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚑 Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionButton(
                    icon: Icons.local_hospital,
                    label: 'Call 911',
                    onTap: () => _callEmergencyNumber('911'),
                    color: Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                    icon: Icons.location_on,
                    label: 'Share Location',
                    onTap: _shareLocation,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildQuickActionButton(
                    icon: Icons.local_gas_station,
                    label: 'Roadside Assistance',
                    onTap: () => _callEmergencyNumber('1-800-AAA-HELP'),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCountdown() {
    return Container(
      color: Colors.red[700],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'SOS ACTIVATED',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Emergency alert in $_countdownSeconds seconds',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text(
                  '$_countdownSeconds',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _cancelSOS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: contact.isPrimary ? Colors.red : Colors.grey,
        child: Text(contact.name[0].toUpperCase()),
      ),
      title: Text(contact.name),
      subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () => EmergencyService.callEmergencyContact(contact),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeContact(contact),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _startSOSCountdown() {
    setState(() {
      _sosCountdown = true;
      _countdownSeconds = 10;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _triggerSOS();
      }
    });
  }

  void _cancelSOS() {
    _countdownTimer?.cancel();
    setState(() {
      _sosCountdown = false;
    });
  }

  Future<void> _triggerSOS() async {
    await EmergencyService.triggerSOS(
      location: 'Current Location', // TODO: Get actual location
      driverName: 'Current Driver', // TODO: Get from driver profile
      additionalInfo: 'Triggered from SafeRide AI app',
    );

    setState(() {
      _sosCountdown = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to all contacts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _callEmergencyNumber(String number) async {
    final phoneUri = Uri.parse('tel:$number');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _shareLocation() async {
    const location = 'Current Location: Latitude, Longitude'; // TODO: Get actual location
    await Share.share(
      'I need assistance. My current location is: $location',
      subject: 'Emergency Location Share',
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationshipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                final contact = EmergencyContact(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                  relationship: relationshipController.text.isNotEmpty 
                    ? relationshipController.text 
                    : 'Emergency Contact',
                );
                setState(() {
                  _contacts.add(contact);
                });
                EmergencyService.setEmergencyContacts(_contacts);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeContact(EmergencyContact contact) {
    setState(() {
      _contacts.removeWhere((c) => c.id == contact.id);
    });
    EmergencyService.setEmergencyContacts(_contacts);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
