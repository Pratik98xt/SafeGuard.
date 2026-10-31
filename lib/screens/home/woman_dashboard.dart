import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

class WomanDashboard extends StatefulWidget {
  const WomanDashboard({super.key});

  @override
  State<WomanDashboard> createState() => _WomanDashboardState();
}

class _WomanDashboardState extends State<WomanDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulsingController;
  late Animation<double> _pulseAnimation;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
  }

  void _startTracking() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
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
    super.dispose();
  }

  void _showEmergencyCallSheet(BuildContext context, List<String> contacts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'EMERGENCY CONTACTS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (contacts.isEmpty)
              const Text('No emergency contacts saved. Add them in Profile.')
            else
              ...contacts.map(
                (phone) => ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.phone, color: Colors.white),
                  ),
                  title: Text(phone),
                  onTap: () {
                    EmergencyService.makeEmergencyCall(phone);
                    Navigator.pop(context);
                  },
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final emergencyProvider = Provider.of<EmergencyProvider>(context);
    final isSOSActive = emergencyProvider.isEmergencyActive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'SafeGuard+',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddGuardianDialog(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${userProvider.currentUser?.name ?? "User"}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Stay safe with real-time protection.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.backgroundBlue,
                  child: Text(
                    userProvider.currentUser?.name.isNotEmpty == true
                        ? userProvider.currentUser!.name.trim()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // 🚨 BIG PULSING SOS BUTTON
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: TapEffect(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Press and hold the SOS button to trigger emergency alert'),
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
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: isSOSActive ? Colors.red : AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isSOSActive
                                        ? Colors.red
                                        : AppTheme.primaryBlue)
                                    .withOpacity(0.5),
                            blurRadius: isSOSActive ? 40 : 20,
                            spreadRadius: isSOSActive ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emergency_share_rounded,
                            color: Colors.white,
                            size: 70,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isSOSActive ? 'SOS ACTIVE' : 'LONG PRESS\nFOR SOS',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // 👥 MY GUARDIANS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MY GUARDIANS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (userProvider.currentUser?.linkedUserIds.isEmpty ?? true)
              _emptyGuardianCard()
            else
              ...userProvider.currentUser!.linkedUserIds.map(
                (uid) => _guardianCard(uid),
              ),

            const SizedBox(height: 30),

            // 🛠 QUICK ACTIONS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'EMERGENCY TOOLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.2,
              children: [
                _actionCard(
                  'Emergency Call',
                  Icons.phone_forwarded_rounded,
                  Colors.indigo,
                  () => _showEmergencyCallSheet(
                    context,
                    userProvider.currentUser?.emergencyContacts ?? [],
                  ),
                ),
                _actionCard(
                  emergencyProvider.isSirenActive ? 'Stop Siren' : 'Siren',
                  Icons.notifications_active_rounded,
                  Colors.red,
                  () => emergencyProvider.toggleSiren(),
                ),
                _actionCard(
                  emergencyProvider.isFlashlightActive
                      ? 'Flashlight OFF'
                      : 'Flashlight ON',
                  Icons.flashlight_on_rounded,
                  Colors.orange,
                  () => emergencyProvider.toggleFlashlight(),
                ),
                _actionCard(
                  'Share Live',
                  Icons.share_location_rounded,
                  Colors.green,
                  () async {
                    Position pos = await EmergencyService.getCurrentPosition();
                    EmergencyService.shareToWhatsApp(pos);
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 🛡 SAFETY TIPS
            _safetyTipCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return TapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guardianCard(String uid) {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final guardian = snapshot.data!;
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.backgroundBlue,
                child: Text(
                  guardian.name.isNotEmpty
                      ? guardian.name.trim()[0].toUpperCase()
                      : 'G',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      guardian.latitude != null
                          ? 'Active Now'
                          : 'Last seen: Just now',
                      style: TextStyle(
                        color: guardian.latitude != null
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TapEffect(
                onTap: () => EmergencyService.makeEmergencyCall(guardian.phone),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Colors.blue, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyGuardianCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_search_rounded, color: Colors.grey, size: 30),
          SizedBox(height: 8),
          Text(
            'No guardians linked yet.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Add a guardian to enable live protection.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _safetyTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Colors.blue, size: 30),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Tip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Always keep your primary guardian informed about your destination when traveling alone.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
