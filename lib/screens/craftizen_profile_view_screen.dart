import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/models/craftizen_model.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/screens/job_request_screen.dart';

class CraftizenProfileViewScreen extends StatelessWidget {
  final String craftizenId;

  const CraftizenProfileViewScreen({Key? key, required this.craftizenId}) : super(key: key);

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 ? '${userId1}_$userId2' : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(craftizenId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Scaffold(body: Center(child: Text('User not found')));

        // Map to CraftizenModel for easier access if needed, or use raw data
        final craftizen = CraftizenModel.fromMap(data, snapshot.data!.id);

        return Scaffold(
          appBar: AppBar(title: Text(craftizen.name)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    child: Text(craftizen.name[0], style: const TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    craftizen.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text(' ${craftizen.rating.toStringAsFixed(1)} Rating'),
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      Text(' ${data['stats']?['completedJobs'] ?? 0} Jobs Done'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: craftizen.skills.map((s) => Chip(label: Text(s))).toList(),
                ),
                const SizedBox(height: 24),
                const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(data['bio'] ?? 'No bio provided.'),
                const SizedBox(height: 24),
                const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Center(child: Text('No reviews yet.')), // Placeholder for reviews list
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to chat")));
                        return;
                      }
                      final chatId = _getChatId(currentUserId, craftizenId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            otherUserName: craftizen.name,
                          )
                        )
                      );
                    },
                    child: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Pre-fill category if possible, or just open generic job post
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const JobRequestScreen()));
                    },
                    child: const Text('Request Job'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
