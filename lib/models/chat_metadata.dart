import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMetadata {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastTimestamp;
  final Map<String, int> unreadCount;
  final String? typing;

  ChatMetadata({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastTimestamp,
    required this.unreadCount,
    this.typing,
  });

  factory ChatMetadata.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMetadata(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastTimestamp: data['lastTimestamp'] ?? Timestamp.now(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      typing: data['typing'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp,
      'unreadCount': unreadCount,
      'typing': typing,
    };
  }
}
