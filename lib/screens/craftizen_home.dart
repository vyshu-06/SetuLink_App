import 'package:flutter/material.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';

class CraftizenHome extends StatelessWidget {
  const CraftizenHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'craftizen_dashboard'),
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
          children: const [
            BilingualText(
              textKey: 'welcome_craftizen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            // Add other Craftizen-specific dashboard widgets here
          ],
        ),
      ),
    );
  }
}
