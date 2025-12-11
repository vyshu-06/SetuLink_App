import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/chat_service.dart';
import 'package:setulink_app/screens/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  Map<String, String> _getPeerInfo(DocumentSnapshot chatDoc, String currentUserId) {
    final List<dynamic> participants = chatDoc['users'];
    final String peerId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    final String peerName = 'User ${peerId.substring(0, 6)}';
    return {'id': peerId, 'name': peerName};
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = ChatService();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: currentUser == null
          ? const Center(child: Text("Please log in to see your chats."))
          : StreamBuilder<QuerySnapshot>(
              stream: chatService.getChatList(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No chats found."));
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    final chat = chatDocs[index];
                    final peerInfo = _getPeerInfo(chat, currentUser.uid);
                    final data = chat.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(peerInfo['name']!),
                      subtitle: Text(data.containsKey('lastMessage') ? data['lastMessage'] ?? '' : ''),
                      onTap: () {
                        if (peerInfo['id']!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.id,
                                otherUserName: peerInfo['name']!,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
