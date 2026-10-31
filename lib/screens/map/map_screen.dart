import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/location_provider.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/services/emergency_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        if (locationProvider.currentLocation == null) {
          locationProvider.getCurrentLocation();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    
    final LatLng initialCenter = locationProvider.currentLocation ?? const LatLng(19.0760, 72.8777);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.women_safety',
              ),
              
              // 📍 Current User Marker
              if (locationProvider.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: locationProvider.currentLocation!,
                      width: 60, height: 60,
                      child: _markerIcon(userProvider.currentUser?.role == 'guardian' ? Colors.indigo : Colors.blue, 
                        userProvider.currentUser?.role == 'child' ? Icons.child_care : Icons.person_pin_circle_rounded),
                    ),
                  ],
                ),

              // 👨‍👩‍👧 Linked Members Markers
              if (currentUser != null && currentUser.linkedUserIds.isNotEmpty)
                ..._buildFamilyMarkers(currentUser.linkedUserIds),
            ],
          ),
          
          // Header Overlay
          _buildMapHeader(),

          // Map Controls
          Positioned(
            bottom: 30, right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'track',
                  onPressed: () {
                    if (currentUser == null) return;
                    setState(() => _isTracking = !_isTracking);
                    if (_isTracking) {
                      locationProvider.startLocationUpdates(
                        currentUser.uid,
                        currentUser.name,
                        currentUser.linkedUserIds,
                        role: currentUser.role,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live Tracking Started')));
                    } else {
                      locationProvider.stopLocationUpdates();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live Tracking Stopped')));
                    }
                  },
                  backgroundColor: _isTracking ? Colors.green : Colors.white,
                  child: Icon(Icons.radar_rounded, color: _isTracking ? Colors.white : AppTheme.primaryBlue),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'share',
                  onPressed: () async {
                    try {
                      final pos = await EmergencyService.getCurrentPosition();
                      await EmergencyService.shareToWhatsApp(pos);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share location: $e')),
                        );
                      }
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.share_location_rounded, color: Colors.green),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'locate',
                  onPressed: () async {
                    if (locationProvider.currentLocation != null) {
                      _mapController.move(locationProvider.currentLocation!, 15);
                    } else {
                      await locationProvider.getCurrentLocation();
                      if (locationProvider.currentLocation != null) {
                        _mapController.move(locationProvider.currentLocation!, 15);
                      }
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: AppTheme.primaryBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFamilyMarkers(List<String> userIds) {
    return userIds.map((uid) {
      return StreamBuilder<UserModel?>(
        stream: _firestoreService.getUserStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.latitude == null) return const SizedBox.shrink();
          final user = snapshot.data!;
          final position = LatLng(user.latitude!, user.longitude!);
          
          return MarkerLayer(
            markers: [
              Marker(
                point: position,
                width: 60, height: 60,
                child: GestureDetector(
                  onTap: () => _mapController.move(position, 16),
                  child: _markerIcon(
                    user.role == 'child' ? Colors.orange : Colors.pink, 
                    user.role == 'child' ? Icons.child_care : Icons.person_pin_circle_rounded, 
                    label: user.name
                  ),
                ),
              ),
            ],
          );
        },
      );
    }).toList();
  }

  Widget _markerIcon(Color color, IconData icon, {String? label}) {
    return Column(
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        Container(
          decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 28),
        ),
      ],
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 50, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          children: [
            const Icon(Icons.security_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 10),
            const Text('LIVE SAFETY NETWORK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
              child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
