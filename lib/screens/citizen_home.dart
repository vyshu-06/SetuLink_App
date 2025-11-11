import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'chat_list_screen.dart';

class CitizenHome extends StatelessWidget {
  const CitizenHome({Key? key}) : super(key: key);

  final List<Map<String, String>> serviceCategories = const [
    {'titleKey': 'everyday_needs'},
    {'titleKey': 'semi_technical'},
    {'titleKey': 'community_skills'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('citizen_dashboard')),
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
            Text(
              tr('welcome_citizen'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Text(
              tr('available_services'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      title: Text(tr(cat['titleKey']!)),
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
