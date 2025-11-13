import 'package:flutter/material.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
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
        title: const BilingualText(textKey: 'citizen_dashboard'),
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
            const BilingualText(
              textKey: 'welcome_citizen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            const BilingualText(
              textKey: 'available_services',
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
                      title: BilingualText(textKey: cat['titleKey']!),
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
