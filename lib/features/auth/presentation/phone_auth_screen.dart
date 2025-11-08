import 'package:flutter/material.dart';

class PhoneAuthScreen extends StatelessWidget {
  final String role;

  const PhoneAuthScreen({required this.role, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Authentication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text('Phone Auth for \$role'),
            const SizedBox(height: 20),
            const Text('This feature is under development'),
          ],
        ),
      ),
    );
  }
}
