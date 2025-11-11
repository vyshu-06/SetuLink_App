import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../models/chat_metadata.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String peerId;
  final String peerName;

  const ChatScreen({
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _chatService.markMessagesAsRead(widget.chatId, widget.currentUserId);
    _messageController.addListener(() {
      _chatService.updateTypingStatus(
        widget.chatId,
        widget.currentUserId,
        _messageController.text.isNotEmpty,
      );
    });
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _messageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _sendMessage() {
    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      receiverId: widget.peerId,
      text: _messageController.text.trim(),
    );
    _messageController.clear();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        receiverId: widget.peerId,
        imageFile: File(pickedFile.path),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        _chatService.sendMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          receiverId: widget.peerId,
          voiceFile: File(path),
        );
      }
    } else {
      await _recorder.startRecorder(toFile: 'voice_note.aac');
    }
    setState(() => _isRecording = !_isRecording);
  }

  Widget _buildMessageBubble(Message message) {
    bool isMe = message.senderId == widget.currentUserId;

    Widget messageContent;
    switch (message.type) {
      case 'image':
        messageContent = Image.network(message.imageUrl!,
            width: 200, height: 200, fit: BoxFit.cover);
        break;
      case 'voice':
        messageContent = IconButton(
          icon: const Icon(Icons.play_circle_fill, size: 40),
          onPressed: () => _audioPlayer.play(UrlSource(message.voiceUrl!)),
        );
        break;
      default:
        messageContent = Text(message.messageText ?? '');
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: messageContent),
            if (isMe) ...[
              const SizedBox(width: 8),
              Icon(
                message.read ? Icons.done_all : Icons.done,
                size: 16,
                color: message.read ? Colors.blue : Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats_metadata')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final metadata = ChatMetadata.fromFirestore(snapshot.data!);
              if (metadata.typing == widget.peerId) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.peerName),
                    const Text('typing...', style: TextStyle(fontSize: 12)),
                  ],
                );
              }
            }
            return Text(widget.peerName);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => _buildMessageBubble(snapshot.data![index]),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.attach_file), onPressed: _pickImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Type a message...'),
              ),
            ),
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _toggleRecording,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
