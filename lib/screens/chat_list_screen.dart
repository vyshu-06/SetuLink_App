import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your chats.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatList(currentUser['uid']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final List<dynamic> users = chatDoc['users'];
              final otherUserId = users.firstWhere((id) => id != currentUser['uid'], orElse: () => '');

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: _chatService.getUserDetails(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text('Loading chat...'));
                  }

                  final otherUser = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final otherUserName = otherUser?['name'] ?? 'Unknown User';

                  return ListTile(
                    leading: CircleAvatar(child: Text(otherUserName.isNotEmpty ? otherUserName[0] : 'U')),
                    title: Text(otherUserName),
                    subtitle: const Text('Tap to open chat'), // Placeholder for last message
                    onTap: () {
                      final chatId = _chatService.getChatId(currentUser['uid'], otherUserId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId,
                            otherUserName: otherUserName,
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
