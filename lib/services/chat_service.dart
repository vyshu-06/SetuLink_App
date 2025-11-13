import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/message.dart';
import '../models/chat_metadata.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String getChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  Stream<List<ChatMetadata>> getChats(String userId) {
    return _firestore
        .collection('chats_metadata')
        .where('participants', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMetadata.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  Future<String> _uploadFile(File file, String path) async {
    final ref = _storage.ref(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    String? text,
    File? imageFile,
    File? voiceFile,
  }) async {
    String? imageUrl;
    String? voiceUrl;
    String type = 'text';
    String lastMessage = text ?? '';

    if (imageFile != null) {
      type = 'image';
      imageUrl = await _uploadFile(
          imageFile, 'chat_images/${DateTime.now().millisecondsSinceEpoch}');
      lastMessage = '📷 Photo';
    } else if (voiceFile != null) {
      type = 'voice';
      voiceUrl = await _uploadFile(
          voiceFile, 'voice_notes/${DateTime.now().millisecondsSinceEpoch}');
      lastMessage = '🎤 Voice Note';
    }

    final message = Message(
      senderId: senderId,
      receiverId: receiverId,
      messageText: text,
      timestamp: Timestamp.now(),
      type: type,
      imageUrl: imageUrl,
      voiceUrl: voiceUrl,
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    await _firestore.collection('chats_metadata').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': lastMessage,
      'lastTimestamp': message.timestamp,
      'unreadCount': {
        receiverId: FieldValue.increment(1),
      },
    }, SetOptions(merge: true));
  }

  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chats_metadata').doc(chatId).set({
      'typing': isTyping ? userId : null,
    }, SetOptions(merge: true));
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    await _firestore.collection('chats_metadata').doc(chatId).set({
      'unreadCount': {
        userId: 0,
      },
    }, SetOptions(merge: true));
  }
}
