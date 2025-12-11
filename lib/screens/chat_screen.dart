import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatScreen({required this.chatId, required this.otherUserName, Key? key})
      : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    final messageStream = _db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == currentUser.uid;

                    if (message['type'] == 'audio') {
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.play_circle_fill),
                          onPressed: () => _audioPlayer.play(UrlSource(message['url'])),
                        ),
                      );
                    }

                    return ListTile(
                      title: Text(message['text'] ?? ''),
                      tileColor: isMe ? Colors.blue[100] : Colors.grey[200],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(currentUser.uid),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(String currentUserId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Enter message'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(currentUserId, 'text', _messageController.text),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _toggleRecording,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String userId, String type, String content) async {
    if (content.isEmpty) return;

    await _db.collection('chats').doc(widget.chatId).collection('messages').add({
      'senderId': userId,
      'type': type,
      'text': type == 'text' ? content : null,
      'url': type == 'audio' ? content : null,
      'timestamp': FieldValue.serverTimestamp(),
    });

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
