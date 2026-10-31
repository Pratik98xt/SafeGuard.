class SOSAlert {
  final String id;
  final String userId;
  final String userName;
  final String type; // SOS, MOVEMENT, STATUS, etc.
  final double latitude;
  final double longitude;
  final String message;
  final DateTime timestamp;
  final String status; // active, resolved

  SOSAlert({
    required this.id,
    required this.userId,
    required this.userName,
    this.type = 'SOS',
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.timestamp,
    this.status = 'active',
    this.message = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'senderId': userId,     // Compatibility with AppNotification
      'senderName': userName, // Compatibility with AppNotification
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  factory SOSAlert.fromMap(Map<String, dynamic> map) {
    return SOSAlert(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: map['type'] ?? 'SOS',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      status: map['status'] ?? 'active',
      message: map['message'] ?? '',
    );
  }
}
