class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // woman, child, guardian
  final String? profileImage;
  final List<String> linkedUserIds;
  final double? latitude;
  final double? longitude;
  final int? batteryLevel;
  final List<String> emergencyContacts;
  final DateTime? lastSeen;
  final String? guardianId; // GDN123456
  final String? address;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.linkedUserIds = const [],
    this.emergencyContacts = const [],
    this.latitude,
    this.longitude,
    this.batteryLevel,
    this.lastSeen,
    this.guardianId,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'linkedUserIds': linkedUserIds,
      'emergencyContacts': emergencyContacts,
      'latitude': latitude,
      'longitude': longitude,
      'batteryLevel': batteryLevel,
      'lastSeen': lastSeen?.toIso8601String(),
      'guardianId': guardianId,
      'address': address,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'woman',
      profileImage: map['profileImage'],
      linkedUserIds: List<String>.from(map['linkedUserIds'] ?? []),
      emergencyContacts: List<String>.from(map['emergencyContacts'] ?? []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      batteryLevel: map['batteryLevel'] as int?,
      lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen']) : null,
      guardianId: map['guardianId'],
      address: map['address'],
    );
  }
}
