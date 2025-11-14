import 'package:flutter/material.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final String name = currentUser?['name'] ?? 'N/A';
    final String email = currentUser?['email'] ?? 'N/A';
    final String phone = currentUser?['phone'] ?? 'N/A';
    final String role = currentUser?['role'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'profile'),
        backgroundColor: role == 'citizen' ? Colors.teal : Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(name),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: Text(email),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.work),
                title: Text(role),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
