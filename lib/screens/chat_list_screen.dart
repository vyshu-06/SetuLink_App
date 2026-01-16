import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/chat_service.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = ChatService();
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'chats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: currentUser == null
          ? const Center(child: BilingualText(textKey: 'log_in_to_see_bookings'))
          : StreamBuilder<QuerySnapshot>(
              stream: chatService.getChatList(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: BilingualText(textKey: 'no_jobs_available')); // Placeholder for No Chats
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: chatDocs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final chat = chatDocs[index];
                    final data = chat.data() as Map<String, dynamic>;
                    final List<dynamic> users = data['users'] ?? [];
                    final String peerId = users.firstWhere((id) => id != currentUser.uid, orElse: () => '');

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(peerId).get(),
                      builder: (context, userSnapshot) {
                        final String peerName = userSnapshot.hasData ? (userSnapshot.data!['name'] ?? 'User') : '...';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                            child: Text(peerName[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            data['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 16),
                          onTap: () {
                            if (peerId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: chat.id,
                                    otherUserName: peerName,
                                  ),
                                ),
                              );
                            }
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
