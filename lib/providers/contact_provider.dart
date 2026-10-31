import 'package:flutter/material.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'dart:async';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;

  EmergencyContact({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toMap() => {'name': name, 'phone': phone};
  factory EmergencyContact.fromMap(Map<String, dynamic> map, String id) =>
      EmergencyContact(
        id: id,
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
      );
}

class ContactProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<EmergencyContact> _contacts = [];
  StreamSubscription? _contactSub;
  String? _uid;
  String? _role;

  List<EmergencyContact> get contacts => _contacts;

  void init(String uid, String role) {
    _uid = uid;
    _role = role;
    _subscribeToContacts();
  }

  void _subscribeToContacts() {
    _contactSub?.cancel();
    if (_uid != null && _role != null) {
      _contactSub = _firestoreService
          .getEmergencyContacts(_uid!, _role!)
          .listen((data) {
            _contacts = data
                .map((item) => EmergencyContact.fromMap(item, item['id']))
                .toList();
            notifyListeners();
          });
    }
  }

  Future<String?> addContact(String name, String phone) async {
    if (_uid == null || _role == null) return 'User context missing';
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty) return 'Contact name cannot be empty';
    if (trimmedPhone.isEmpty) return 'Phone number cannot be empty';

    try {
      await _firestoreService.saveEmergencyContact(_uid!, _role!, {
        'name': trimmedName,
        'phone': trimmedPhone,
      });
      return null;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return e.toString();
    }
  }

  Future<String?> editContact(
    String contactId,
    String name,
    String phone,
  ) async {
    if (_uid == null || _role == null) return 'User context missing';
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    if (trimmedName.isEmpty) return 'Contact name cannot be empty';
    if (trimmedPhone.isEmpty) return 'Phone number cannot be empty';

    try {
      await _firestoreService.updateEmergencyContact(_uid!, _role!, contactId, {
        'name': trimmedName,
        'phone': trimmedPhone,
      });
      return null;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return e.toString();
    }
  }

  Future<String?> deleteContact(String contactId) async {
    if (_uid == null || _role == null) return 'User context missing';
    try {
      await _firestoreService.deleteEmergencyContact(_uid!, _role!, contactId);
      return null;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return e.toString();
    }
  }

  @override
  void dispose() {
    _contactSub?.cancel();
    super.dispose();
  }
}
