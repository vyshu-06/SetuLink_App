import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  final String role;

  const RegisterScreen({required this.role, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text('Registration for \$role'),
            const SizedBox(height: 20),
            const Text('This feature is under development'),
          ],
        ),
      ),
    );
  }
}
