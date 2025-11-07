// Filename: lib/screens/greeting_page.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({Key? key}) : super(key: key);

  // Save selected role to SharedPreferences
  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setBool('auto_login', true); // optional: enable auto-login
  }

  // Navigate to login screen for selected role
  void _navigateToLogin(BuildContext context, String role) async {
    await _saveRole(role);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(role: role),
      ),
    );
  }

  // Check if a role is stored in SharedPreferences
  Future<String?> _checkStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final autoLogin = prefs.getBool('auto_login') ?? false;
    if (role != null && autoLogin) return role;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<String?>(
          future: _checkStoredRole(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final storedRole = snapshot.data;

            // If role exists, auto-navigate to login screen
            if (storedRole != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(role: storedRole),
                  ),
                );
              });
              return const SizedBox.shrink(); // temporary blank screen
            }

            // Normal greeting page UI
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Icon(
                      Icons.handshake,
                      size: 80,
                      color: Colors.teal[600],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SetuLink',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('welcome_msg'),
                      style: const TextStyle(fontSize: 18.0),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Citizen button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _navigateToLogin(context, 'citizen'),
                      child: Text(
                        tr('i_am_user') + " (नागररक)",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Craftizen button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _navigateToLogin(context, 'craftizen'),
                      child: Text(
                        tr('i_am_craftizen') + " (कला-नागररक)",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      child: Text(
                        tr('register_here'),
                        style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
