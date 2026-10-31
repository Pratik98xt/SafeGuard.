import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:women_safety/models/sos_alert_model.dart';
import 'dart:convert';

class OfflineService {
  static const String _pendingSOSKey = 'pending_sos_alerts';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  OfflineService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      if (result != ConnectivityResult.none) {
        _syncPendingAlerts();
      }
    });
  }

  Future<void> saveSOSLocally(SOSAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingSOSKey) ?? [];
    pending.add(jsonEncode(alert.toMap()));
    await prefs.setStringList(_pendingSOSKey, pending);
  }

  Future<void> _syncPendingAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingSOSKey) ?? [];

    if (pending.isEmpty) return;

    for (String alertStr in pending) {
      try {
        final alertMap = jsonDecode(alertStr);
        final alert = SOSAlert.fromMap(alertMap);
        // Write to notifications collection directly for offline sync
        await FirebaseFirestore.instance.collection('notifications').doc(alert.id).set(alert.toMap());
      } catch (e) {
        debugPrint('Sync error: $e');
      }
    }

    await prefs.remove(_pendingSOSKey);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
