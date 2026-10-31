import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:women_safety/models/user_model.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> getNearbyUsers(Position currentPos, double radiusInKm) async {
    QuerySnapshot snapshot = await _db.collection('public_locations').get();
    List<UserModel> nearby = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['latitude'] != null && data['longitude'] != null) {
        double lat = (data['latitude'] as num).toDouble();
        double lon = (data['longitude'] as num).toDouble();
        double distance = Geolocator.distanceBetween(
          currentPos.latitude, currentPos.longitude, lat, lon,
        ) / 1000;
        
        if (distance <= radiusInKm) {
          nearby.add(UserModel(
            uid: data['uid'] ?? doc.id,
            name: data['name'] ?? 'User',
            role: data['role'] ?? 'woman',
            email: '',
            phone: '',
            latitude: lat,
            longitude: lon,
          ));
        }
      }
    }
    return nearby;
  }

  Future<void> createPost({
    required String userId,
    required String userName,
    required String content,
    bool isUrgent = false,
  }) async {
    await _db.collection('community_posts').add({
      'userId': userId,
      'userName': userName,
      'content': content,
      'isUrgent': isUrgent,
      'likes': 0,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return _db.collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<void> likePost(String postId) async {
    try {
      await _db.collection('community_posts').doc(postId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error liking post: $e');
    }
  }

  Future<void> broadcastCommunitySOS({
    required String userId,
    required String userName,
    required String message,
    required Position position,
  }) async {
    await _db.collection('community_notifications').add({
      'userId': userId,
      'userName': userName,
      'message': message,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': 'COMMUNITY_SOS',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
