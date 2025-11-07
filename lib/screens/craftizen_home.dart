import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenHome extends StatelessWidget {
  final Map<String, dynamic> userObj;
  const CitizenHome({required this.userObj, Key? key}) : super(key: key);

  // Service categories
  final List<Map<String, String>> serviceCategories = [
    {'title': 'everyday_needs', 'key': 'non_technical'},
    {'title': 'semi_technical', 'key': 'semi_technical'},
    {'title': 'community_skill', 'key': 'community_skill'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('citizen_dashboard'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
              "${'welcome'.tr()}, ${userObj['name'] ?? ''}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 24),
            Text(
              'available_services'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: serviceCategories.length,
                itemBuilder: (context, index) {
                  final cat = serviceCategories[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(Icons.category, color: Colors.teal),
                      title: Text(cat['title']!.tr()),
                      subtitle: Text('browse_services'.tr()),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to service list screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${'navigating_to'.tr()} ${cat['title']!.tr()}'),
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