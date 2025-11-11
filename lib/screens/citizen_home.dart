import 'package:flutter/material.dart';
import 'chat_list_screen.dart'; // Import the new screen

class CitizenHome extends StatelessWidget {
  // FIX: Constructor no longer requires userObj. User data should be fetched via a provider.
  const CitizenHome({Key? key}) : super(key: key);

  final List<Map<String, String>> serviceCategories = const [
    {'title': 'Everyday Needs', 'key': 'non_technical'},
    {'title': 'Semi Technical', 'key': 'semi_technical'},
    {'title': 'Community Skills', 'key': 'community_skill'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Citizen!", // Placeholder text
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: serviceCategories.length,
                itemBuilder: (context, index) {
                  final cat = serviceCategories[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(cat['title']!),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigation logic will be handled by the router
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
