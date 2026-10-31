import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/models/request_model.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/widgets/tap_effect.dart';
import 'package:women_safety/screens/map/map_screen.dart';

class GuardianDashboard extends StatefulWidget {
  const GuardianDashboard({super.key});

  @override
  State<GuardianDashboard> createState() => _GuardianDashboardState();
}

class _GuardianDashboardState extends State<GuardianDashboard> {
  final TextEditingController _inviteController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Guardian'),
        content: TextField(
          controller: _inviteController,
          decoration: const InputDecoration(
            hintText: 'Enter Guardian Name or ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final query = _inviteController.text.trim();
              if (query.isNotEmpty) {
                final guardians = await _firestoreService.searchGuardians(
                  query,
                );
                if (context.mounted) {
                  if (guardians.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invitation sent to ${guardians.first.name}!',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Guardian does not exist')),
                    );
                  }
                }
              }
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  void _broadcastSOS(UserModel guardian) async {
    if (guardian.linkedUserIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No members linked to broadcast SOS.')),
        );
      }
      return;
    }

    for (String uid in guardian.linkedUserIds) {
      final String notificationId = DateTime.now().millisecondsSinceEpoch.toString() + uid;
      await _firestoreService.sendAppNotification(
        AppNotification(
          id: notificationId,
          type: 'SOS',
          senderId: guardian.uid,
          senderName: guardian.name,
          receiverId: uid,
          message: 'Guardian ${guardian.name} is broadcasting an emergency alert!',
          timestamp: DateTime.now(),
        ),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS Broadcasted to all linked members!')),
      );
    }
  }

  void _sendAlertToMember(UserModel sender, UserModel receiver) async {
    final String notificationId = DateTime.now().millisecondsSinceEpoch.toString() + receiver.uid;
    await _firestoreService.sendAppNotification(
      AppNotification(
        id: notificationId,
        type: 'status_check',
        senderId: sender.uid,
        senderName: sender.name,
        receiverId: receiver.uid,
        message:
            '${sender.name} is checking on you. Please respond if you are safe.',
        timestamp: DateTime.now(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alert sent to ${receiver.name}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final requests = userProvider.incomingRequests;
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Guardian Monitor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () =>
                _showUIDDialog(context, currentUser?.guardianId ?? 'N/A'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(currentUser?.name ?? 'Guardian'),
              const SizedBox(height: 30),

              // 📩 Incoming Requests
              if (requests.isNotEmpty) ...[
                const Text(
                  'PENDING REQUESTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 130,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: requests.length,
                    itemBuilder: (context, index) =>
                        _requestCard(context, userProvider, requests[index]),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // 👥 Linked Members
              const Text(
                'LINKED MEMBERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (currentUser?.linkedUserIds.isEmpty ?? true)
                _emptyState(
                  'No members linked yet',
                  'Share your ID to start monitoring loved ones.',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentUser!.linkedUserIds.length,
                  itemBuilder: (context, index) => _memberTile(
                    currentUser,
                    currentUser.linkedUserIds[index],
                  ),
                ),

              const SizedBox(height: 30),

              // 🛠 Monitoring Tools
              const Text(
                'QUICK TOOLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.6,
                children: [
                  _toolCard(
                    'Broadcast SOS',
                    Icons.emergency_share_rounded,
                    Colors.red,
                    () => _broadcastSOS(currentUser!),
                  ),
                  _toolCard(
                    'Live Track',
                    Icons.map_rounded,
                    Colors.indigo,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    ),
                  ),
                  _toolCard(
                    'SOS History',
                    Icons.history_edu_rounded,
                    Colors.orange,
                    () {},
                  ),
                  _toolCard(
                    'Invite Guardian',
                    Icons.person_add_rounded,
                    Colors.purple,
                    _showInviteDialog,
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.backgroundBlue,
          child: Icon(
            Icons.security_rounded,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Monitoring active status.',
              style: TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _requestCard(
    BuildContext context,
    UserProvider provider,
    GuardianRequest request,
  ) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.fromName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Role: ${request.fromRole.toUpperCase()}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'Accept',
                  Colors.green,
                  () async {
                    final error = await provider.respondToRequest(
                      request.id,
                      RequestStatus.accepted,
                    );
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to accept request: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  'Reject',
                  Colors.red,
                  () async {
                    final error = await provider.respondToRequest(
                      request.id,
                      RequestStatus.rejected,
                    );
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to reject request: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberTile(UserModel? currentUser, String uid) {
    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final user = snapshot.data!;
        final isOnline = user.latitude != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.backgroundBlue,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name.trim()[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${user.role.toUpperCase()} • ${isOnline ? "Active" : "Offline"}',
                          style: TextStyle(
                            color: isOnline
                                ? Colors.green
                                : Colors.grey.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      TapEffect(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.indigo,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TapEffect(
                        onTap: () => _sendAlertToMember(currentUser!, user),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notification_important_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return TapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _toolCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return TapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUIDDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardian Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Others can add you using this ID:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                uid,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
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
