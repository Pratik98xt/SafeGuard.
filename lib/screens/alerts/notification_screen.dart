import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/widgets/tap_effect.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<AppNotification>>(
              stream: firestoreService.getNotificationsByReceiver(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to load notifications: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final notifications = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final note = notifications[index];
                    return TapEffect(
                      onTap: () => firestoreService.markNotificationAsRead(note.id),
                      child: _buildNotificationCard(note),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(AppNotification note) {
    final DateTime timestamp = note.timestamp;
    final String timeStr = DateFormat('hh:mm a, dd MMM').format(timestamp);
    final String type = note.type;
    final String name = note.senderName;

    Color color = Colors.blue;
    IconData icon = Icons.notifications_rounded;

    if (type.contains('SOS') || type.contains('emergency')) {
      color = Colors.red;
      icon = Icons.emergency_rounded;
    } else if (type.contains('status') || type.contains('safe')) {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (type.contains('message') || type.contains('comment')) {
      color = Colors.indigo;
      icon = Icons.message_rounded;
    } else if (type.contains('request')) {
      color = Colors.orange;
      icon = Icons.person_add_rounded;
    } else if (type.contains('movement')) {
      color = Colors.purple;
      icon = Icons.directions_walk_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: note.isRead ? Colors.white : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: note.isRead ? Colors.grey.shade100 : color.withOpacity(0.1)),
        boxShadow: note.isRead ? [] : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: note.isRead ? Colors.grey.shade700 : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.message,
                  style: TextStyle(
                    fontSize: 13, 
                    color: note.isRead ? Colors.grey.shade600 : Colors.black87,
                    fontWeight: note.isRead ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!note.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 20),
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your notification history is empty',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
