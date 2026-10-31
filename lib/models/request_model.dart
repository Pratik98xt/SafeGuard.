enum RequestStatus { pending, accepted, rejected }

class GuardianRequest {
  final String id;
  final String fromId;
  final String toId;
  final String fromName;
  final String fromPhone;
  final String fromRole;
  final RequestStatus status;
  final DateTime timestamp;

  GuardianRequest({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.fromName,
    required this.fromPhone,
    required this.fromRole,
    this.status = RequestStatus.pending,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'fromName': fromName,
      'fromPhone': fromPhone,
      'fromRole': fromRole,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GuardianRequest.fromMap(Map<String, dynamic> map) {
    return GuardianRequest(
      id: map['id'] ?? '',
      fromId: map['fromId'] ?? '',
      toId: map['toId'] ?? '',
      fromName: map['fromName'] ?? '',
      fromPhone: map['fromPhone'] ?? '',
      fromRole: map['fromRole'] ?? 'woman',
      status: RequestStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => RequestStatus.pending),
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }
}
