import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String receiverId;
  final String? messageText; // Can be null for media messages
  final Timestamp timestamp;
  final bool read;
  final String type; // 'text', 'image', or 'voice'
  final String? imageUrl;
  final String? voiceUrl;

  Message({
    required this.senderId,
    required this.receiverId,
    this.messageText,
    required this.timestamp,
    this.read = false,
    required this.type,
    this.imageUrl,
    this.voiceUrl,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      messageText: data['messageText'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      read: data['read'] ?? false,
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      voiceUrl: data['voiceUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': messageText,
      'timestamp': timestamp,
      'read': read,
      'type': type,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
    };
  }
}
