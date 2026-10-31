import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyService {
  static final Telephony telephony = Telephony.instance;
  static bool _isSirenPlaying = false;

  static Future<void> makeEmergencyCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch emergency call');
    }
  }

  static Future<void> sendDirectSMS(
    List<String> recipients,
    String message,
  ) async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted ?? false) {
      for (String phone in recipients) {
        telephony.sendSms(to: phone, message: message);
      }
    } else {
      debugPrint('SMS Permissions Denied');
    }
  }

  static Future<void> shareToWhatsApp(
    Position position, {
    String? customMessage,
  }) async {
    final String lat = position.latitude.toString();
    final String lon = position.longitude.toString();
    final String osmLink = 'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon';
    final String message =
        customMessage ??
        '🚨 EMERGENCY SOS 🚨\nI am in danger. My live location: $osmLink';
    await Share.share(
      message + (customMessage != null ? '\nLive Location: $osmLink' : ''),
    );
  }

  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<void> triggerSiren() async {
    try {
      if (_isSirenPlaying) {
        await FlutterRingtonePlayer().stop();
        _isSirenPlaying = false;
        debugPrint('Alarm stopped');
      } else {
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.alarm,
          ios: IosSounds.alarm,
          looping: true,
          volume: 1.0,
          asAlarm: true,
        );
        _isSirenPlaying = true;
        debugPrint('Alarm triggered');
      }
    } catch (e) {
      _isSirenPlaying = false;
      debugPrint('Error playing/stopping alarm: $e');
    }
  }

  static Future<void> stopSiren() async {
    try {
      await FlutterRingtonePlayer().stop();
      _isSirenPlaying = false;
      debugPrint('Alarm stopped');
    } catch (e) {
      _isSirenPlaying = false;
      debugPrint('Error stopping alarm: $e');
    }
  }

  static Future<void> toggleFlashlight(bool isOn) async {
    bool hasTorch = await TorchLight.isTorchAvailable();
    if (!hasTorch) {
      debugPrint('Torch not available');
      return;
    }
    try {
      if (isOn) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (e) {
      debugPrint('Error toggling flashlight: $e');
    }
  }

  static Future<void> triggerVibration() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [500, 1000, 500, 2000], repeat: 1);
    }
  }

  static Future<void> stopVibration() async {
    Vibration.cancel();
  }

  static Future<void> logAlert({
    required String senderId,
    required String senderName,
    required List<String> receiverIds,
    required String type,
    required String message,
    double? lat,
    double? lon,
  }) async {
    debugPrint('🚨 EmergencyService.logAlert called');
    debugPrint('   Type: $type');
    debugPrint('   Sender: $senderName ($senderId)');
    debugPrint('   Receivers: ${receiverIds.join(", ")}');
    debugPrint('   Message: $message');

    for (String receiverId in receiverIds) {
      final String notificationId =
          DateTime.now().millisecondsSinceEpoch.toString() + receiverId;
      debugPrint(
        '   Creating notification for receiver: $receiverId (ID: $notificationId)',
      );

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'type': type,
            'senderId': senderId,
            'senderName': senderName,
            'receiverId': receiverId,
            'message': message,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'unread',
            if (lat != null && lon != null)
              'location': {'lat': lat, 'lon': lon},
          });

      debugPrint('   ✅ Notification created for $receiverId');
    }

    debugPrint('🚨 EmergencyService.logAlert completed');
  }
}
