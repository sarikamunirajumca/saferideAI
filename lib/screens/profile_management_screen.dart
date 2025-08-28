import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/driver_profile_service.dart';
import '../utils/constants.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  List<DriverProfile> _profiles = [];
  DriverProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await DriverProfileService.getProfiles();
    final current = await DriverProfileService.getCurrentProfile();
    setState(() {
      _profiles = profiles;
      _currentProfile = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Driver Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateProfileDialog,
          ),
        ],
      ),
      body: _profiles.isEmpty 
        ? _buildEmptyState()
        : _buildProfileList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_add,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No driver profiles yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a profile to personalize your experience',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateProfileDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final isActive = _currentProfile?.id == profile.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? AppConstants.primaryColor : Colors.grey,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              profile.name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: _getSafetyScoreColor(profile.safetyScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Safety Score: ${profile.safetyScore.toInt()}%',
                      style: TextStyle(
                        color: _getSafetyScoreColor(profile.safetyScore),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  const Chip(
                    label: Text('Active', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleProfileAction(value, profile),
                  itemBuilder: (context) => [
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Set as Active'),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'stats',
                      child: Text('View Stats'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSafetyScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _handleProfileAction(String action, DriverProfile profile) async {
    switch (action) {
      case 'activate':
        await DriverProfileService.setCurrentProfile(profile.id);
        _loadProfiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.name} is now the active profile')),
        );
        break;
      case 'edit':
        _showEditProfileDialog(profile);
        break;
      case 'stats':
        _showProfileStats(profile);
        break;
      case 'delete':
        _showDeleteConfirmation(profile);
        break;
    }
  }

  void _showCreateProfileDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Driver Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                await DriverProfileService.createDefaultProfile(
                  nameController.text,
                  emailController.text,
                );
                Navigator.pop(context);
                _loadProfiles();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(DriverProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedProfile = DriverProfile(
                id: profile.id,
                name: nameController.text,
                email: emailController.text,
                photoUrl: profile.photoUrl,
                createdAt: profile.createdAt,
                preferences: profile.preferences,
                detectionCounts: profile.detectionCounts,
                safetyScore: profile.safetyScore,
              );
              await DriverProfileService.saveProfile(updatedProfile);
              Navigator.pop(context);
              _loadProfiles();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showProfileStats(DriverProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.name} - Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Safety Score', '${profile.safetyScore.toInt()}%'),
            _buildStatRow('Drowsiness Events', '${profile.detectionCounts['drowsiness'] ?? 0}'),
            _buildStatRow('Distraction Events', '${profile.detectionCounts['distraction'] ?? 0}'),
            _buildStatRow('Phone Usage', '${profile.detectionCounts['phoneUsage'] ?? 0}'),
            _buildStatRow('Total Events', '${profile.detectionCounts.values.fold<int>(0, (sum, count) => sum + count)}'),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DriverProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete ${profile.name}\'s profile? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DriverProfileService.deleteProfile(profile.id);
              Navigator.pop(context);
              _loadProfiles();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
