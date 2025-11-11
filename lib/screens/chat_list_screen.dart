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
      // Handle case where user is not logged in
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Text('Please log in to see your chats.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<ChatMetadata>>(
        stream: _chatService.getChats(currentUser['uid']),
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
              final otherUserId = chat.user1 == currentUser['uid'] ? chat.user2 : chat.user1;

              // We need to fetch the other user's name to display it
              // This is a simplified version; in a real app, you might cache user data
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final otherUserData = userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(otherUserData['name'] ?? 'Unknown User'),
                    subtitle: Text(chat.lastMessage),
                    trailing: (chat.unreadCountUser1 > 0 && chat.user1 == currentUser['uid']) || (chat.unreadCountUser2 > 0 && chat.user2 == currentUser['uid']) ? const CircleAvatar(radius: 8, backgroundColor: Colors.red) : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chat.chatId,
                            currentUserId: currentUser['uid'],
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
