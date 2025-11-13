import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chat_metadata.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Text('Please log in to see your chats.'),
        ),
      );
    }

    final currentUserId = currentUser['uid'] as String;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<ChatMetadata>>(
        stream: _chatService.getChats(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          final chats = snapshot.data!;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Correctly find the other user's ID from the participants list
              final otherUserId = chat.participants.firstWhere((id) => id != currentUserId, orElse: () => '');

              if (otherUserId.isEmpty) return const SizedBox.shrink(); // Should not happen

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>;
                  // Correctly get the unread count from the map
                  final unreadCount = chat.unreadCount[currentUserId] ?? 0;

                  return ListTile(
                    title: Text(otherUserData['name'] ?? 'Unknown User'),
                    subtitle: Text(chat.lastMessage),
                    trailing: unreadCount > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat.chatId,
                            currentUserId: currentUserId,
                            peerId: otherUserId,
                            peerName: otherUserData['name'] ?? 'Unknown User',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
