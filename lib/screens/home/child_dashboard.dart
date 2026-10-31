import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/providers/emergency_provider.dart';
import 'package:women_safety/providers/location_provider.dart';
import 'package:women_safety/services/emergency_service.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/widgets/add_guardian_dialog.dart';
import 'package:women_safety/widgets/tap_effect.dart';
import 'package:women_safety/models/user_model.dart';

class ChildDashboard extends StatefulWidget {
  const ChildDashboard({super.key});

  @override
  State<ChildDashboard> createState() => _ChildDashboardState();
}

class _ChildDashboardState extends State<ChildDashboard> with TickerProviderStateMixin {
  late AnimationController _pulsingController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
  }

  void _startTracking() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user != null) {
      locationProvider.startLocationUpdates(
        user.uid,
        user.name,
        user.linkedUserIds,
        role: user.role,
      );
    }
  }

  @override
  void dispose() {
    _pulsingController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final isSOSActive = emergencyProvider.isEmergencyActive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Safety Shield (Child)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => showDialog(context: context, builder: (_) => const AddGuardianDialog()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Safe Zone Status Card
            _safeZoneCard(),
            const SizedBox(height: 40),

            // Animated SOS Button
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: TapEffect(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Press and hold the button to trigger help alert'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onLongPress: () {
                      EmergencyService.triggerVibration();
                      emergencyProvider.triggerEmergency(context, userProvider);
                    },
                    child: Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        color: isSOSActive ? Colors.red : Colors.orange.shade600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isSOSActive ? Colors.red : Colors.orange).withOpacity(0.4),
                            blurRadius: 30, spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emergency_rounded, color: Colors.white, size: 60),
                          const SizedBox(height: 10),
                          const Text('I NEED HELP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                          const Text('LONG PRESS', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Quick Status Buttons
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('QUICK STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                _statusChip('At School', Icons.school, Colors.blue, () => emergencyProvider.sendQuickStatus(userProvider, 'reached school')),
                _statusChip('At Home', Icons.home, Colors.green, () => emergencyProvider.sendQuickStatus(userProvider, 'reached home')),
                _statusChip('Heading Home', Icons.directions_walk, Colors.purple, () => emergencyProvider.sendQuickStatus(userProvider, 'heading home')),
                _statusChip('Need Pickup', Icons.hail_rounded, Colors.teal, () => emergencyProvider.sendQuickStatus(userProvider, 'need pickup')),
                _statusChip('Reached Dest.', Icons.location_on, Colors.indigo, () => emergencyProvider.sendQuickStatus(userProvider, 'reached destination')),
                _statusChip('Feeling Unsafe', Icons.warning_amber_rounded, Colors.amber.shade900, () => emergencyProvider.sendQuickStatus(userProvider, 'feeling unsafe')),
                _statusChip('In Emergency', Icons.emergency, Colors.red, () => emergencyProvider.sendQuickStatus(userProvider, 'in emergency')),
                _statusChip('Need Help', Icons.help_center, Colors.orange, () => emergencyProvider.sendQuickStatus(userProvider, 'need help')),
                _statusChip('Traveling Alone', Icons.directions_bus, Colors.deepPurple, () => emergencyProvider.sendQuickStatus(userProvider, 'traveling alone')),
              ],
            ),
            const SizedBox(height: 30),

            // Custom Message Field
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message to guardians...',
                filled: true, fillColor: Colors.grey.shade100,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppTheme.primaryBlue),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      emergencyProvider.sendCustomMessage(userProvider, _messageController.text);
                      _messageController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent to guardians.')));
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // Guardians List
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('MY GUARDIANS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: userProvider.currentUser?.linkedUserIds.isEmpty ?? true
                ? const Center(child: Text('No guardians linked.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: userProvider.currentUser?.linkedUserIds.length ?? 0,
                    itemBuilder: (context, index) {
                      final guardianId = userProvider.currentUser!.linkedUserIds[index];
                      return StreamBuilder<UserModel?>(
                        stream: _firestoreService.getUserStream(guardianId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final guardian = snapshot.data!;
                          return Container(
                            margin: const EdgeInsets.only(right: 20),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppTheme.backgroundBlue,
                                  child: Text(
                                    guardian.name.isNotEmpty
                                        ? guardian.name.trim()[0].toUpperCase()
                                        : 'G',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(guardian.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  guardian.latitude != null ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: guardian.latitude != null ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safeZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.green, size: 30),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOU ARE SAFE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Location: School Zone', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
