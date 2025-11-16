import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('notifications_title'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return Center(child: Text(context.tr('no_notifications')));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              final title = notif['title'] ?? context.tr('notification');
              final body = notif['body'] ?? '';
              final timestamp = (notif['timestamp'] as Timestamp?)?.toDate();

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(title),
                subtitle: Text(body),
                trailing: Text(
                  timestamp != null
                      ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                      : '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  // Optionally, mark as read or navigate
                },
              );
            },
          );
        },
      ),
    );
  }
}
