import 'package:flutter/material.dart';

class CitizenHome extends StatelessWidget {
  final Map<String, dynamic> userObj;

  const CitizenHome({required this.userObj, Key? key}) : super(key: key);

  // Service categories with hardcoded titles to avoid translation issues
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
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Add logout functionality here
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
              "Welcome, ${userObj['name'] ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.category, color: Colors.teal),
                      title: Text(cat['title']!),
                      subtitle: const Text('Browse Services'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to service list screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Navigating to ${cat['title']!}'),
                          ),
                        );
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