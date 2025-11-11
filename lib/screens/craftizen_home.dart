import 'package:flutter/material.dart';
import 'chat_list_screen.dart'; // Import the new screen

class CraftizenHome extends StatefulWidget {
  // FIX: Constructor no longer requires userObj.
  const CraftizenHome({Key? key}) : super(key: key);

  @override
  State<CraftizenHome> createState() => _CraftizenHomeState();
}

class _CraftizenHomeState extends State<CraftizenHome> {
  // ... (rest of the file is placeholder and can remain)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Craftizen Dashboard'),
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
      body: const Center(child: Text("Welcome, Craftizen!")),
    );
  }
}
