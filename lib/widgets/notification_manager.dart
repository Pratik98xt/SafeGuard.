import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:vibration/vibration.dart';

class NotificationManager extends StatefulWidget {
  final Widget child;
  const NotificationManager({super.key, required this.child});

  @override
  State<NotificationManager> createState() => _NotificationManagerState();
}

class _NotificationManagerState extends State<NotificationManager> {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  void initState() {
    super.initState();
    // We don't subscribe here because we need the UserProvider which is available in build
    // But we need a way to listen only once. 
    // Actually, listening in build with StreamBuilder is safer for lifecycle, 
    // or using a didChangeDependencies to get provider and listen.
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) return widget.child;

    return StreamBuilder<List<AppNotification>>(
      stream: _firestoreService.getNotificationsByReceiver(user.uid),
      builder: (context, snapshot) {
        // We only want to react to NEW notifications, or changes. 
        // A simple StreamBuilder rebuilds on every update.
        // For a global listener, we might want to process the list 
        // and show alerts for any "unread" high priority ones.
        
        if (snapshot.hasData) {
          final notifications = snapshot.data!;
          // Filter for unread SOS alerts
          final sosAlerts = notifications.where((n) => 
            n.type == 'SOS' && !n.isRead
          ).toList();

          if (sosAlerts.isNotEmpty) {
            // Trigger side effects (sound/UI) *carefully*
            // We should avoid triggering repeatedly if build is called often.
            // Using a post-frame callback to show dialog if not already shown?
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleSOSAlerts(context, sosAlerts);
            });
          }
        }

        return widget.child;
      },
    );
  }

  void _handleSOSAlerts(BuildContext context, List<AppNotification> alerts) {
    // Check if a dialog is already open? 
    // For simplicity, we'll just show a snackbar with high priority or a banner
    // But since this is SOS, we should probably play sound.
    
    // Play sound only if not already playing or recently played? 
    // For this MVP, let's play sound once per batch.
    
    // Note: This might loop if we don't mark them as seen locally or on server.
    // The FirestoreService doesn't auto-mark read.
    
    // Let's just vibrate for now to avoid sound loop issues without state management
    Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
    
    final alert = alerts.first; // Show first one
    
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.red,
        content: Text(
          '🚨 SOS ALERT: ${alert.message}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              // Mark as read so it doesn't show again
               _firestoreService.markNotificationAsRead(alert.id);
            },
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
               ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
               _firestoreService.markNotificationAsRead(alert.id);
               // Navigate to map?
               // Navigator.push(...) 
            },
            child: const Text('VIEW', style: TextStyle(color: Colors.white)), 
          ),
        ],
      ),
    );
  }
}
