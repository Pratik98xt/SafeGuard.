class AppNotification {
  final String id;
  final String type; // login, request_sent, request_accepted, sos, movement, community_post, etc.
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': isRead ? 'read' : 'unread',
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      type: map['type'] ?? 'info',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['status'] == 'read',
    );
  }
}
