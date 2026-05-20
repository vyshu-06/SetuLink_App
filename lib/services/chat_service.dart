import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getChatList(String userId) {
    return _db
        .collection('chats')
        .where('users', arrayContains: userId)
        .snapshots();
  }

  Future<DocumentSnapshot> getUserDetails(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  String getChatId(String userId1, String userId2) {
    // Ensure consistent chat ID regardless of who starts the chat
    return userId1.hashCode <= userId2.hashCode
        ? '$userId1-$userId2'
        : '$userId2-$userId1';
  }

  Future<void> deleteChatMessages(String chatId) async {
    final messages = await _db.collection('chats').doc(chatId).collection('messages').get();
    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    // Also clear last message metadata
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': FieldValue.delete(),
      'lastTimestamp': FieldValue.delete(),
    });
    await batch.commit();
  }
}
