import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/services/firestore_service.dart';

class LocationProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  LatLng? _currentLocation;
  LatLng? _lastNotifiedPos;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionSub;
  final double _movementThreshold = 200.0; // 200 meters

  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      Position position = await _determinePosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startLocationUpdates(
    String uid,
    String userName,
    List<String> linkedUserIds, {
    String role = 'woman',
  }) {
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          _currentLocation = LatLng(position.latitude, position.longitude);

          // Update location in Firestore for user & linked family
          _firestoreService.updateUserLocation(
            uid,
            position.latitude,
            position.longitude,
            100,
          );

          // Update public location for nearby community safety
          _firestoreService.updatePublicLocation(
            uid,
            userName,
            role,
            position.latitude,
            position.longitude,
          );

          // Check for significant movement to notify guardians
          if (_lastNotifiedPos == null) {
            _lastNotifiedPos = _currentLocation;
          } else {
            double distance = Geolocator.distanceBetween(
              _lastNotifiedPos!.latitude,
              _lastNotifiedPos!.longitude,
              _currentLocation!.latitude,
              _currentLocation!.longitude,
            );

            if (distance >= _movementThreshold) {
              _lastNotifiedPos = _currentLocation;
              _notifyGuardiansOfMovement(
                uid,
                userName,
                linkedUserIds,
                position,
              );
            }
          }

          notifyListeners();
        });
  }

  void _notifyGuardiansOfMovement(
    String uid,
    String userName,
    List<String> linkedUserIds,
    Position pos,
  ) {
    for (String guardianId in linkedUserIds) {
      _firestoreService.sendAppNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString() + guardianId,
          type: 'movement',
          senderId: uid,
          senderName: userName,
          receiverId: guardianId,
          message: '$userName is on the move. Current location updated.',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void stopLocationUpdates() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
