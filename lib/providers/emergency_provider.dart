import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:women_safety/services/emergency_service.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'package:women_safety/providers/user_provider.dart';

class EmergencyProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEmergencyActive = false;
  bool _isSirenActive = false;
  bool _isFlashlightActive = false;

  bool get isEmergencyActive => _isEmergencyActive;
  bool get isSirenActive => _isSirenActive;
  bool get isFlashlightActive => _isFlashlightActive;

  static String buildSosSmsMessage(double lat, double lon) {
    final String googleMapsLink = 'https://maps.google.com/?q=$lat,$lon';
    final String osmLink = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon';
    return '🚨 SOS! EMERGENCY ALERT: I am in danger. My live location: $googleMapsLink (OSM: $osmLink)';
  }

  Future<void> triggerEmergency(
    BuildContext context,
    UserProvider userProvider,
  ) async {
    if (userProvider.currentUser == null) return;

    debugPrint('🆘 EmergencyProvider.triggerEmergency called');
    debugPrint('   User: ${userProvider.currentUser!.name}');
    debugPrint(
      '   Linked guardians: ${userProvider.currentUser!.linkedUserIds.length}',
    );

    _isEmergencyActive = true;
    _isSirenActive = true;
    _isFlashlightActive = true;
    notifyListeners();

    try {
      // 1. Trigger Siren, Vibration & Flashlight
      await EmergencyService.triggerSiren();
      await EmergencyService.triggerVibration();
      await EmergencyService.toggleFlashlight(true);

      // 2. Get High Accuracy Location
      Position pos = await EmergencyService.getCurrentPosition();

      // 3. Log Notification in Firestore
      debugPrint('   Sending SOS notifications...');
      await EmergencyService.logAlert(
        senderId: userProvider.currentUser!.uid,
        senderName: userProvider.currentUser!.name,
        receiverIds: userProvider.currentUser!.linkedUserIds,
        type: 'SOS',
        message: '🚨 SOS! EMERGENCY ALERT TRIGGERED',
        lat: pos.latitude,
        lon: pos.longitude,
      );

      // 4. Send SMS to Emergency Contacts & Guardians
      final currentUser = userProvider.currentUser!;
      final Set<String> recipients = {};

      // Load contacts from Firestore subcollection (child_emergency_contacts / women_emergency_contacts)
      try {
        final savedContacts = await _firestoreService.getEmergencyContactsOnce(
          currentUser.uid,
          currentUser.role,
        );
        for (final contact in savedContacts) {
          final phone = (contact['phone'] as String?)?.trim();
          if (phone != null && phone.isNotEmpty) {
            recipients.add(phone);
          }
        }
      } catch (err) {
        debugPrint('Error fetching emergency contacts subcollection: $err');
      }

      // Load contacts from user's emergencyContacts list if present
      for (final phone in currentUser.emergencyContacts) {
        final trimmed = phone.trim();
        if (trimmed.isNotEmpty) {
          recipients.add(trimmed);
        }
      }

      // Load phone numbers from linked guardians
      for (final guardianId in currentUser.linkedUserIds) {
        try {
          final guardian = await _firestoreService.getUser(guardianId);
          if (guardian != null && guardian.phone.trim().isNotEmpty) {
            recipients.add(guardian.phone.trim());
          }
        } catch (err) {
          debugPrint('Error fetching guardian $guardianId: $err');
        }
      }

      final String smsMessage = buildSosSmsMessage(pos.latitude, pos.longitude);

      if (recipients.isNotEmpty) {
        await EmergencyService.sendDirectSMS(recipients.toList(), smsMessage);
      }

      // 5. Automated Emergency Call
      await EmergencyService.makeEmergencyCall('112');

      // 6. Share Location Link with Custom Message support if needed
      await EmergencyService.shareToWhatsApp(pos);

      if (context.mounted) {
        if (recipients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'SOS triggered, but no emergency contacts found! Please add contacts in your profile.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'SOS Triggered! Alert SMS sent to ${recipients.length} contact(s).',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('SOS Error: $e');
      _isEmergencyActive = false;
      _isSirenActive = false;
      _isFlashlightActive = false;
      await EmergencyService.stopSiren();
      await EmergencyService.toggleFlashlight(false);
      await EmergencyService.stopVibration();
      notifyListeners();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> shareLocationWithMessage(String customMessage) async {
    try {
      Position pos = await EmergencyService.getCurrentPosition();
      await EmergencyService.shareToWhatsApp(pos, customMessage: customMessage);
    } catch (e) {
      debugPrint('Location Share Error: $e');
    }
  }

  Future<void> toggleSiren() async {
    await EmergencyService.triggerSiren();
    _isSirenActive = !_isSirenActive;
    notifyListeners();
  }

  Future<void> toggleFlashlight() async {
    _isFlashlightActive = !_isFlashlightActive;
    await EmergencyService.toggleFlashlight(_isFlashlightActive);
    notifyListeners();
  }

  Future<void> stopEmergency() async {
    _isEmergencyActive = false;
    _isSirenActive = false;
    _isFlashlightActive = false;
    await EmergencyService.stopSiren();
    await EmergencyService.stopVibration();
    await EmergencyService.toggleFlashlight(false);
    notifyListeners();
  }

  Future<void> sendQuickStatus(UserProvider userProvider, String status) async {
    if (userProvider.currentUser == null) return;
    debugPrint('📍 EmergencyProvider.sendQuickStatus called');
    debugPrint('   Status: $status');
    debugPrint('   User: ${userProvider.currentUser!.name}');
    debugPrint(
      '   Linked guardians: ${userProvider.currentUser!.linkedUserIds.length}',
    );

    try {
      Position pos = await EmergencyService.getCurrentPosition();
      await EmergencyService.logAlert(
        senderId: userProvider.currentUser!.uid,
        senderName: userProvider.currentUser!.name,
        receiverIds: userProvider.currentUser!.linkedUserIds,
        type: 'status_update',
        message: status,
        lat: pos.latitude,
        lon: pos.longitude,
      );
      debugPrint('✅ Quick status sent successfully');
    } catch (e) {
      debugPrint('❌ Status Error: $e');
    }
  }

  Future<void> sendCustomMessage(
    UserProvider userProvider,
    String message,
  ) async {
    if (userProvider.currentUser == null) return;
    debugPrint('💬 EmergencyProvider.sendCustomMessage called');
    debugPrint('   Message: $message');
    debugPrint('   User: ${userProvider.currentUser!.name}');
    debugPrint(
      '   Linked guardians: ${userProvider.currentUser!.linkedUserIds.length}',
    );

    try {
      Position pos = await EmergencyService.getCurrentPosition();
      await EmergencyService.logAlert(
        senderId: userProvider.currentUser!.uid,
        senderName: userProvider.currentUser!.name,
        receiverIds: userProvider.currentUser!.linkedUserIds,
        type: 'message',
        message: message,
        lat: pos.latitude,
        lon: pos.longitude,
      );
      debugPrint('✅ Custom message sent successfully');
    } catch (e) {
      debugPrint('❌ Message Error: $e');
    }
  }
}
