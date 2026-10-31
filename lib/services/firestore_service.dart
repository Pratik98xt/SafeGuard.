import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/models/request_model.dart';
import 'package:women_safety/models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Operations
  Future<void> saveUser(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateLinkedUserIds(String uid, List<String> linkedIds) async {
    await _db.collection('users').doc(uid).update({
      'linkedUserIds': linkedIds,
    });
  }

  Future<UserModel?> getUserByGuardianId(String gdnId) async {
    var snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'guardian')
        .where('guardianId', isEqualTo: gdnId)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    var snapshot = await _db
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<UserModel?> getUser(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) return UserModel.fromMap(doc.data()!);
    return null;
  }

  Future<void> updateUserLocation(
    String uid,
    double lat,
    double lng,
    int battery,
  ) async {
    await _db.collection('users').doc(uid).update({
      'latitude': lat,
      'longitude': lng,
      'batteryLevel': battery,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePublicLocation(
    String uid,
    String name,
    String role,
    double lat,
    double lng,
  ) async {
    // Store approximate coordinates (rounded to 3 decimal places ~110m resolution)
    final double approxLat = double.parse(lat.toStringAsFixed(3));
    final double approxLng = double.parse(lng.toStringAsFixed(3));

    await _db.collection('public_locations').doc(uid).set({
      'uid': uid,
      'name': name,
      'role': role,
      'latitude': approxLat,
      'longitude': approxLng,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Guardian Request Operations
  Future<void> sendGuardianRequest(GuardianRequest request) async {
    await _db
        .collection('guardian_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  Stream<List<GuardianRequest>> getIncomingRequests(String toUserId) {
    return _db
        .collection('guardian_requests')
        .where('toId', isEqualTo: toUserId)
        .where('status', isEqualTo: RequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GuardianRequest.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateRequestStatus(
    String requestId,
    RequestStatus status,
  ) async {
    await _db.collection('guardian_requests').doc(requestId).update({
      'status': status.name,
    });
  }

  // SOS Alert / Notification Operations
  Future<void> sendAppNotification(AppNotification notification) async {
    debugPrint('📤 Creating notification: ${notification.id}');
    debugPrint('   Type: ${notification.type}');
    debugPrint(
      '   From: ${notification.senderName} (${notification.senderId})',
    );
    debugPrint('   To: ${notification.receiverId}');
    debugPrint('   Message: ${notification.message}');

    await _db
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());

    debugPrint('✅ Notification created successfully');
  }

  Stream<List<AppNotification>> getNotificationsByReceiver(String receiverId) {
    debugPrint('🔍 Fetching notifications for user: $receiverId');

    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: receiverId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('❌ Error fetching notifications: $error');
          // debugPrint('   This might be a missing Firestore index. Check Firebase Console.');
        })
        .map((snapshot) {
          debugPrint(
            '📬 Received ${snapshot.docs.length} notifications for $receiverId',
          );
          return snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'status': 'read',
    });
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _db
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<AppNotification>> getActiveAlerts(List<String> receiverIds) {
    if (receiverIds.isEmpty) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('receiverId', whereIn: receiverIds)
        .where('type', isEqualTo: 'SOS')
        .where(
          'status',
          isNotEqualTo: 'read',
        ) // Or just use a specific field for alert state
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> resolveAlert(String alertId) async {
    await _db.collection('notifications').doc(alertId).update({
      'status': 'resolved',
    });
  }

  // Role-based Emergency Contacts
  String _getContactCollection(String role) {
    return role == 'child'
        ? 'child_emergency_contacts'
        : 'women_emergency_contacts';
  }

  Future<void> saveEmergencyContact(
    String uid,
    String role,
    Map<String, dynamic> contact,
  ) async {
    await _db
        .collection(_getContactCollection(role))
        .doc(uid)
        .collection('contacts')
        .add(contact);
  }

  Future<void> updateEmergencyContact(
    String uid,
    String role,
    String contactId,
    Map<String, dynamic> contact,
  ) async {
    await _db
        .collection(_getContactCollection(role))
        .doc(uid)
        .collection('contacts')
        .doc(contactId)
        .update(contact);
  }

  Future<List<Map<String, dynamic>>> getEmergencyContactsOnce(
    String uid,
    String role,
  ) async {
    final snapshot = await _db
        .collection(_getContactCollection(role))
        .doc(uid)
        .collection('contacts')
        .get();
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> getEmergencyContacts(
    String uid,
    String role,
  ) {
    return _db
        .collection(_getContactCollection(role))
        .doc(uid)
        .collection('contacts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<void> deleteEmergencyContact(
    String uid,
    String role,
    String contactId,
  ) async {
    await _db
        .collection(_getContactCollection(role))
        .doc(uid)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  Future<List<UserModel>> searchGuardians(String query) async {
    // Firestore doesn't support case-insensitive search easily without external services
    // For now, we'll search by exact guardianId or name
    var snap1 = await _db
        .collection('users')
        .where('role', isEqualTo: 'guardian')
        .where('guardianId', isEqualTo: query)
        .get();
    var snap2 = await _db
        .collection('users')
        .where('role', isEqualTo: 'guardian')
        .where('name', isEqualTo: query)
        .get();

    Set<UserModel> results = {};
    for (var doc in snap1.docs) {
      results.add(UserModel.fromMap(doc.data()));
    }
    for (var doc in snap2.docs) {
      results.add(UserModel.fromMap(doc.data()));
    }
    return results.toList();
  }
}
