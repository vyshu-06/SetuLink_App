import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';

class CraftizenHome extends StatefulWidget {
  const CraftizenHome({Key? key}) : super(key: key);

  @override
  State<CraftizenHome> createState() => _CraftizenHomeState();
}

class _CraftizenHomeState extends State<CraftizenHome> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final User? user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Craftizen Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacementNamed('/greeting');
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${user?.displayName ?? 'Craftizen'}!"),
            // Add other Craftizen-specific UI elements here
          ],
        ),
      ),
    );
  }
}
