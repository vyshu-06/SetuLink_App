import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeMessage {
  final String senderId;
  final String message;
  final Timestamp timestamp;

  DisputeMessage({
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  factory DisputeMessage.fromMap(Map<String, dynamic> data) {
    return DisputeMessage(
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}

class DisputeModel {
  final String id;
  final String jobId;
  final String raisedBy;
  final String craftizenId;
  final String type; // "payment", "quality", "other"
  final String description;
  final String status; // "open", "in_review", "resolved", "rejected"
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final List<DisputeMessage> messages;
  final bool escalationRequested;

  DisputeModel({
    required this.id,
    required this.jobId,
    required this.raisedBy,
    required this.craftizenId,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.escalationRequested,
  });

  factory DisputeModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisputeModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      raisedBy: data['raisedBy'] ?? '',
      craftizenId: data['craftizenId'] ?? '',
      type: data['type'] ?? 'other',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      messages: (data['messages'] as List<dynamic>? ?? [])
          .map((m) => DisputeMessage.fromMap(m as Map<String, dynamic>))
          .toList(),
      escalationRequested: data['escalationRequested'] ?? false,
    );
  }
}
