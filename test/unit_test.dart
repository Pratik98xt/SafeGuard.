import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:women_safety/models/user_model.dart';
import 'package:women_safety/models/request_model.dart';
import 'package:women_safety/models/notification_model.dart';
import 'package:women_safety/providers/user_provider.dart';
import 'package:women_safety/providers/emergency_provider.dart';
import 'package:women_safety/providers/contact_provider.dart';

void main() {
  group('Guardian ID Generator Tests', () {
    test('generateGuardianId produces GDN followed by 6 digits', () {
      final id = UserProvider.generateGuardianId();
      expect(RegExp(r'^GDN\d{6}$').hasMatch(id), isTrue);
    });

    test('generateGuardianId is deterministic when given seeded Random', () {
      final id1 = UserProvider.generateGuardianId(Random(42));
      final id2 = UserProvider.generateGuardianId(Random(42));
      expect(id1, equals(id2));
      expect(RegExp(r'^GDN\d{6}$').hasMatch(id1), isTrue);
    });
  });

  group('SOS SMS Message Builder Tests', () {
    test('buildSosSmsMessage formats Google Maps and OSM coordinates correctly', () {
      const lat = 19.0760;
      const lon = 72.8777;
      final message = EmergencyProvider.buildSosSmsMessage(lat, lon);

      expect(message, contains('🚨 SOS! EMERGENCY ALERT'));
      expect(message, contains('https://maps.google.com/?q=19.076,72.8777'));
      expect(message, contains('https://www.openstreetmap.org/?mlat=19.076&mlon=72.8777'));
    });
  });

  group('UserModel Serialization Tests', () {
    test('round-trip serialization with all fields', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'user123',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1234567890',
        role: 'woman',
        profileImage: null,
        linkedUserIds: ['guardian1', 'guardian2'],
        emergencyContacts: ['+9876543210'],
        latitude: 12.9716,
        longitude: 77.5946,
        batteryLevel: 85,
        lastSeen: now,
        guardianId: 'GDN654321',
        address: '123 Safe St',
      );

      final map = user.toMap();
      final fromMap = UserModel.fromMap(map);

      expect(fromMap.uid, equals('user123'));
      expect(fromMap.name, equals('Jane Doe'));
      expect(fromMap.email, equals('jane@example.com'));
      expect(fromMap.phone, equals('+1234567890'));
      expect(fromMap.role, equals('woman'));
      expect(fromMap.linkedUserIds, equals(['guardian1', 'guardian2']));
      expect(fromMap.emergencyContacts, equals(['+9876543210']));
      expect(fromMap.latitude, equals(12.9716));
      expect(fromMap.longitude, equals(77.5946));
      expect(fromMap.batteryLevel, equals(85));
      expect(fromMap.guardianId, equals('GDN654321'));
      expect(fromMap.address, equals('123 Safe St'));
    });

    test('fromMap handles minimal map with defaults', () {
      final user = UserModel.fromMap({
        'uid': 'user456',
        'name': 'Bob',
        'email': 'bob@example.com',
        'phone': '12345',
      });

      expect(user.uid, equals('user456'));
      expect(user.role, equals('woman')); // default
      expect(user.linkedUserIds, isEmpty);
      expect(user.emergencyContacts, isEmpty);
      expect(user.latitude, isNull);
    });
  });

  group('GuardianRequest Serialization Tests', () {
    test('round-trip serialization with pending status', () {
      final now = DateTime.now();
      final request = GuardianRequest(
        id: 'req_001',
        fromId: 'user_a',
        toId: 'user_b',
        fromName: 'Alice',
        fromPhone: '+1111111111',
        fromRole: 'woman',
        status: RequestStatus.pending,
        timestamp: now,
      );

      final map = request.toMap();
      expect(map['status'], equals('pending'));

      final parsed = GuardianRequest.fromMap(map);
      expect(parsed.id, equals('req_001'));
      expect(parsed.fromId, equals('user_a'));
      expect(parsed.toId, equals('user_b'));
      expect(parsed.status, equals(RequestStatus.pending));
    });

    test('fromMap fallback to pending for invalid status', () {
      final parsed = GuardianRequest.fromMap({
        'id': 'req_002',
        'fromId': 'a',
        'toId': 'b',
        'fromName': 'A',
        'fromPhone': '123',
        'fromRole': 'child',
        'status': 'unknown_status',
      });

      expect(parsed.status, equals(RequestStatus.pending));
    });
  });

  group('AppNotification Serialization Tests', () {
    test('round-trip serialization with read/unread mapping', () {
      final now = DateTime.now();
      final unread = AppNotification(
        id: 'notif_1',
        type: 'SOS',
        senderId: 'sender_1',
        senderName: 'Sender',
        receiverId: 'receiver_1',
        message: 'Help needed',
        timestamp: now,
        isRead: false,
      );

      expect(unread.toMap()['status'], equals('unread'));
      final parsedUnread = AppNotification.fromMap(unread.toMap());
      expect(parsedUnread.isRead, isFalse);

      final read = AppNotification(
        id: 'notif_2',
        type: 'SOS',
        senderId: 'sender_1',
        senderName: 'Sender',
        receiverId: 'receiver_1',
        message: 'Resolved',
        timestamp: now,
        isRead: true,
      );

      expect(read.toMap()['status'], equals('read'));
      final parsedRead = AppNotification.fromMap(read.toMap());
      expect(parsedRead.isRead, isTrue);
    });
  });

  group('EmergencyContact Model Tests', () {
    test('toMap and fromMap', () {
      final contact = EmergencyContact(
        id: 'contact_123',
        name: 'Doctor John',
        phone: '+919876543210',
      );

      final map = contact.toMap();
      expect(map['name'], equals('Doctor John'));
      expect(map['phone'], equals('+919876543210'));

      final parsed = EmergencyContact.fromMap(map, 'contact_123');
      expect(parsed.id, equals('contact_123'));
      expect(parsed.name, equals('Doctor John'));
      expect(parsed.phone, equals('+919876543210'));
    });
  });
}

