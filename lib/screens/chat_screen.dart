import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({required this.chatId, required this.otherUserName, Key? key})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _initRecorder() async {
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        // Handle denied permission
      }
    }
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return const Scaffold(body: Center(child: BilingualText(textKey: 'log_in_to_see_bookings')));

    final messageStream = _db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: StreamBuilder<QuerySnapshot>(
                  stream: messageStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.fromLTRB(16, kToolbarHeight + MediaQuery.of(context).padding.top + 20, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index].data() as Map<String, dynamic>;
                        final isMe = message['senderId'] == currentUser.uid;

                        return _buildMessageBubble(message, isMe);
                      },
                    );
                  },
                ),
              ),
            ),
            _buildMessageComposer(currentUser.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message['type'] == 'audio')
              IconButton(
                icon: Icon(Icons.play_circle_fill, color: isMe ? AppColors.primaryColor : Colors.white, size: 32),
                onPressed: () => _audioPlayer.play(UrlSource(message['url'])),
              )
            else
              Text(
                message['text'] ?? '',
                style: TextStyle(color: isMe ? Colors.black87 : Colors.white, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(String currentUserId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: _isRecording ? Colors.red : AppColors.primaryColor),
              onPressed: _toggleRecording,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: tr('search_services'), // Using search_services as placeholder for 'Enter message'
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primaryColor),
              onPressed: () => _sendMessage(currentUserId, 'text', _messageController.text),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String userId, String type, String content) async {
    if (content.isEmpty) return;

    final batch = _db.batch();
    
    // Add message to subcollection
    final msgRef = _db.collection('chats').doc(widget.chatId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': userId,
      'type': type,
      'text': type == 'text' ? content : 'Voice Message',
      'url': type == 'audio' ? content : null,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update parent chat document for the Chat List metadata
    final chatRef = _db.collection('chats').doc(widget.chatId);
    batch.set(chatRef, {
      'lastMessage': type == 'text' ? content : 'Voice Message',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'users': widget.chatId.split('_'), // Ensure users array exists
    }, SetOptions(merge: true));

    await batch.commit();
    _messageController.clear();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        final file = File(path);
        final ref = FirebaseStorage.instance.ref('audio_messages/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.aac');
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        _sendMessage(_authService.getCurrentUser()!.uid, 'audio', url);
      }
    } else {
      await _recorder.startRecorder(toFile: 'audio.aac');
      setState(() {
        _isRecording = true;
      });
    }
  }
}
