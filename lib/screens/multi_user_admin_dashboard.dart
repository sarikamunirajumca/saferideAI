import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/detection_service.dart';

class MultiUserStream {
  final String userId;
  final String userName;
  final String vehicleId;
  final String sessionId;
  final DateTime connectedAt;
  final bool isActive;
  final String streamUrl;
  final Map<String, dynamic> detectionStats;
  final String location;
  final String status;

  MultiUserStream({
    required this.userId,
    required this.userName,
    required this.vehicleId,
    required this.sessionId,
    required this.connectedAt,
    required this.isActive,
    required this.streamUrl,
    required this.detectionStats,
    required this.location,
    required this.status,
  });
}

class MultiUserAdminDashboard extends StatefulWidget {
  const MultiUserAdminDashboard({Key? key}) : super(key: key);

  @override
  State<MultiUserAdminDashboard> createState() => _MultiUserAdminDashboardState();
}

class _MultiUserAdminDashboardState extends State<MultiUserAdminDashboard> {
  List<MultiUserStream> _activeStreams = [];
  MultiUserStream? _selectedStream;
  Timer? _refreshTimer;
  String _selectedView = 'grid'; // 'grid', 'single', 'list'

  @override
  void initState() {
    super.initState();
    _loadActiveStreams();
    // Refresh streams every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadActiveStreams();
    });
  }

  Future<void> _loadActiveStreams() async {
    // In a real implementation, this would fetch from a backend service
    // For demo purposes, creating mock data
    setState(() {
      _activeStreams = [
        MultiUserStream(
          userId: 'user1',
          userName: 'John Doe',
          vehicleId: 'SR-001',
          sessionId: 'session-123',
          connectedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          isActive: true,
          streamUrl: 'https://stream1.saferide.com/live',
          detectionStats: {
            'drowsiness': 2,
            'distraction': 5,
            'yawning': 3,
            'totalEvents': 10,
          },
          location: 'Downtown, City A',
          status: 'Driving',
        ),
        MultiUserStream(
          userId: 'user2',
          userName: 'Jane Smith',
          vehicleId: 'SR-002',
          sessionId: 'session-456',
          connectedAt: DateTime.now().subtract(const Duration(minutes: 8)),
          isActive: true,
          streamUrl: 'https://stream2.saferide.com/live',
          detectionStats: {
            'drowsiness': 0,
            'distraction': 1,
            'yawning': 0,
            'totalEvents': 1,
          },
          location: 'Highway 101, City B',
          status: 'Driving',
        ),
        MultiUserStream(
          userId: 'user3',
          userName: 'Mike Johnson',
          vehicleId: 'SR-003',
          sessionId: 'session-789',
          connectedAt: DateTime.now().subtract(const Duration(minutes: 32)),
          isActive: false,
          streamUrl: 'https://stream3.saferide.com/live',
          detectionStats: {
            'drowsiness': 1,
            'distraction': 2,
            'yawning': 1,
            'totalEvents': 4,
          },
          location: 'Parking Lot, Mall C',
          status: 'Parked',
        ),
      ];
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🚗 Multi-User Admin Dashboard (${_activeStreams.length} devices)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_selectedView == 'grid' ? Icons.grid_view : 
                      _selectedView == 'single' ? Icons.crop_16_9 : Icons.list),
            onPressed: _showViewOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveStreams,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    final activeCount = _activeStreams.where((s) => s.isActive).length;
    final totalEvents = _activeStreams
        .map((s) => s.detectionStats['totalEvents'] as int)
        .fold(0, (sum, events) => sum + events);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Active Streams',
              '$activeCount',
              Icons.videocam,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Devices',
              '${_activeStreams.length}',
              Icons.devices,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Events',
              '$totalEvents',
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Critical Alerts',
              '${_getCriticalAlerts()}',
              Icons.emergency,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_activeStreams.isEmpty) {
      return _buildEmptyState();
    }

    switch (_selectedView) {
      case 'grid':
        return _buildGridView();
      case 'single':
        return _buildSingleView();
      case 'list':
        return _buildListView();
      default:
        return _buildGridView();
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Active Streams',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Waiting for users to connect...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _activeStreams.length,
      itemBuilder: (context, index) {
        final stream = _activeStreams[index];
        return _buildStreamCard(stream, isGrid: true);
      },
    );
  }

  Widget _buildSingleView() {
    if (_selectedStream == null && _activeStreams.isNotEmpty) {
      _selectedStream = _activeStreams.first;
    }

    return Column(
      children: [
        // Stream selector
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _activeStreams.length,
            itemBuilder: (context, index) {
              final stream = _activeStreams[index];
              final isSelected = _selectedStream?.userId == stream.userId;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text('${stream.userName} (${stream.vehicleId})'),
                  onSelected: (_) => setState(() => _selectedStream = stream),
                  backgroundColor: stream.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                  selectedColor: Colors.deepPurple.shade100,
                ),
              );
            },
          ),
        ),
        // Selected stream
        Expanded(
          child: _selectedStream != null 
            ? _buildStreamCard(_selectedStream!, isGrid: false)
            : const Center(child: Text('No stream selected')),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeStreams.length,
      itemBuilder: (context, index) {
        final stream = _activeStreams[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildStreamListTile(stream),
        );
      },
    );
  }

  Widget _buildStreamCard(MultiUserStream stream, {required bool isGrid}) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stream.isActive ? Colors.green : Colors.grey,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    stream.userName[0],
                    style: TextStyle(
                      color: stream.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stream.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        stream.vehicleId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  stream.isActive ? Icons.videocam : Icons.videocam_off,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
          
          // Video feed area
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Simulated video feed
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: stream.isActive 
                          ? [Colors.blue.shade900, Colors.black]
                          : [Colors.grey.shade700, Colors.black],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            stream.isActive ? Icons.live_tv : Icons.tv_off,
                            size: isGrid ? 40 : 60,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stream.isActive ? 'LIVE FEED' : 'OFFLINE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isGrid ? 12 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Status indicators
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stream.isActive ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stream.isActive ? 'LIVE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Event count badge
                  if (stream.detectionStats['totalEvents'] > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stream.detectionStats['totalEvents']} events',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Stream info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        stream.location,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(DateTime.now().difference(stream.connectedAt)),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      stream.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: stream.isActive ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamListTile(MultiUserStream stream) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stream.isActive ? Colors.green : Colors.grey,
          child: Text(
            stream.userName[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(stream.userName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${stream.vehicleId} • ${stream.location}'),
            Text('${stream.detectionStats['totalEvents']} events • ${stream.status}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              stream.isActive ? Icons.videocam : Icons.videocam_off,
              color: stream.isActive ? Colors.green : Colors.grey,
            ),
            Text(
              _formatDuration(DateTime.now().difference(stream.connectedAt)),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedStream = stream;
            _selectedView = 'single';
          });
        },
      ),
    );
  }

  void _showViewOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'View Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.grid_view),
              title: const Text('Grid View'),
              onTap: () {
                setState(() => _selectedView = 'grid');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_16_9),
              title: const Text('Single View'),
              onTap: () {
                setState(() => _selectedView = 'single');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('List View'),
              onTap: () {
                setState(() => _selectedView = 'list');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getCriticalAlerts() {
    return _activeStreams
        .map((s) => s.detectionStats['drowsiness'] as int)
        .fold(0, (sum, count) => sum + count);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
