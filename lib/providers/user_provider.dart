import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/models/request_model.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/services/auth_service.dart';
import 'package:women_safety/services/firestore_service.dart';
import 'dart:async';
import 'dart:math';

enum UserRole { woman, child, guardian, none }

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  List<GuardianRequest> _incomingRequests = [];
  StreamSubscription? _userSub;
  StreamSubscription? _requestSub;

  UserModel? get currentUser => _currentUser;
  List<GuardianRequest> get incomingRequests => _incomingRequests;
  UserRole get selectedRole => _getUserRole(_currentUser?.role);

  UserProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.user.listen((user) {
      if (user != null) {
        _subscribeToUserData(user.uid);
      } else {
        _currentUser = null;
        _incomingRequests = [];
        _cancelSubscriptions();
        notifyListeners();
      }
    });
  }

  void _subscribeToUserData(String uid) {
    _cancelSubscriptions();
    _userSub = _firestoreService.getUserStream(uid).listen((userData) {
      _currentUser = userData;
      if (userData?.role == 'guardian') {
        _subscribeToRequests(uid);
      }
      notifyListeners();
    });
  }

  void _subscribeToRequests(String uid) {
    _requestSub = _firestoreService.getIncomingRequests(uid).listen((requests) {
      _incomingRequests = requests;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _userSub?.cancel();
    _requestSub?.cancel();
  }

  UserRole _getUserRole(String? role) {
    switch (role) {
      case 'woman':
        return UserRole.woman;
      case 'child':
        return UserRole.child;
      case 'guardian':
        return UserRole.guardian;
      default:
        return UserRole.none;
    }
  }

  static String generateGuardianId([Random? random]) {
    final rng = random ?? Random();
    final digits = rng.nextInt(900000) + 100000; // 6 digits
    return 'GDN$digits';
  }

  Future<UserModel?> fetchCurrentUser(String uid) async {
    try {
      final user = await _firestoreService.getUser(uid);
      if (user != null) {
        _currentUser = user;
        _subscribeToUserData(uid);
        notifyListeners();
      }
      return user;
    } catch (e) {
      debugPrint('Error fetching current user: $e');
      return null;
    }
  }

  // Auth Actions
  Future<String?> registerUser(
    String name,
    String email,
    String phone,
    String password,
    UserRole role,
  ) async {
    String? error = await _authService.register(email, password);
    if (error == null) {
      // Success
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          UserModel newUser = UserModel(
            uid: user.uid,
            name: name.trim(),
            email: email.trim(),
            phone: phone.trim(),
            role: role.name,
            guardianId: generateGuardianId(),
          );
          await _firestoreService.saveUser(newUser);
          _currentUser = newUser;
          _subscribeToUserData(user.uid);
          notifyListeners();
          return null; // Success
        } catch (e) {
          debugPrint('Error saving user profile: $e');
          return 'Failed to save profile: $e';
        }
      }
      return "User creation failed after auth";
    }
    return error;
  }

  Future<String?> loginUser(String email, String password) async {
    return await _authService.signIn(email.trim(), password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _incomingRequests = [];
    notifyListeners();
  }

  // Profile Actions
  Future<String?> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    if (_currentUser == null) return "User not logged in";

    try {
      final updatedUser = UserModel.fromMap({
        ..._currentUser!.toMap(),
        if (name != null) 'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (address != null) 'address': address.trim(),
      });

      await _firestoreService.saveUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return e.toString();
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint('Change Password Error: $e');
      return false;
    }
  }

  // Request Actions
  Future<bool> sendRequestByGuardianId(String gdnId) async {
    if (_currentUser == null) return false;

    try {
      // Search for guardian by ID
      UserModel? guardian = await _firestoreService.getUserByGuardianId(gdnId);
      if (guardian == null || guardian.role != 'guardian') return false;

      // Cannot send request to self
      if (guardian.uid == _currentUser!.uid) return false;

      // Already linked
      if (_currentUser!.linkedUserIds.contains(guardian.uid)) return false;

      GuardianRequest request = GuardianRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fromId: _currentUser!.uid,
        toId: guardian.uid,
        fromName: _currentUser!.name,
        fromPhone: _currentUser!.phone,
        fromRole: _currentUser!.role,
        timestamp: DateTime.now(),
      );
      await _firestoreService.sendGuardianRequest(request);

      // Trigger Global Notification for Guardian
      final String notificationId =
          DateTime.now().millisecondsSinceEpoch.toString() + guardian.uid;
      await _firestoreService.sendAppNotification(
        AppNotification(
          id: notificationId,
          type: 'guardian_request',
          senderId: _currentUser!.uid,
          senderName: _currentUser!.name,
          receiverId: guardian.uid,
          message: 'You have a new guardian request from ${_currentUser!.name}.',
          timestamp: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Error sending guardian request: $e');
      return false;
    }
  }

  Future<String?> respondToRequest(String requestId, RequestStatus status) async {
    if (_currentUser == null) return 'No user logged in';

    try {
      final reqIndex = _incomingRequests.indexWhere(
        (element) => element.id == requestId,
      );
      if (reqIndex == -1) return 'Request not found';
      final req = _incomingRequests[reqIndex];

      await _firestoreService.updateRequestStatus(requestId, status);

      if (status == RequestStatus.accepted) {
        // Update Guardian (current user)
        List<String> updatedLinked = List<String>.from(_currentUser!.linkedUserIds);
        if (!updatedLinked.contains(req.fromId)) {
          updatedLinked.add(req.fromId);
        }
        await _firestoreService.updateLinkedUserIds(_currentUser!.uid, updatedLinked);
        _currentUser = UserModel.fromMap({
          ..._currentUser!.toMap(),
          'linkedUserIds': updatedLinked,
        });
        notifyListeners();

        // Update Sender (ward) using updateLinkedUserIds for firestore.rules compatibility
        UserModel? sender = await _firestoreService.getUser(req.fromId);
        if (sender != null) {
          List<String> senderLinked = List<String>.from(sender.linkedUserIds);
          if (!senderLinked.contains(_currentUser!.uid)) {
            senderLinked.add(_currentUser!.uid);
          }
          await _firestoreService.updateLinkedUserIds(sender.uid, senderLinked);
        }
      }

      // Notify member whether accepted or rejected
      final notifyType = status == RequestStatus.accepted
          ? 'request_accepted'
          : 'request_rejected';
      final msg = status == RequestStatus.accepted
          ? '${_currentUser!.name} accepted your guardian request.'
          : '${_currentUser!.name} declined your guardian request.';

      final String notificationId =
          DateTime.now().millisecondsSinceEpoch.toString() + req.fromId;
      await _firestoreService.sendAppNotification(
        AppNotification(
          id: notificationId,
          type: notifyType,
          senderId: _currentUser!.uid,
          senderName: _currentUser!.name,
          receiverId: req.fromId,
          message: msg,
          timestamp: DateTime.now(),
        ),
      );

      return null;
    } catch (e) {
      debugPrint('Error responding to request: $e');
      return e.toString();
    }
  }

  Future<void> setRole(UserRole role) async {
    if (_currentUser == null) return;

    // Convert enum to string
    String roleString = role.name;

    // Update local model
    _currentUser = UserModel.fromMap({
      ..._currentUser!.toMap(),
      'role': roleString,
    });

    // Save to Firestore
    await _firestoreService.saveUser(_currentUser!);

    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
