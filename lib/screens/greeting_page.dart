import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({Key? key}) : super(key: key);

  Future<void> _saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
  }

  void _navigateToLogin(BuildContext context, String role) async {
    await _saveRole(role);
    Navigator.pushNamed(context, '/login', arguments: role);
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register', arguments: 'citizen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Icon(Icons.handshake_outlined, size: 80, color: Colors.teal[700]),
              const SizedBox(height: 20),
              const BilingualText(
                textKey: 'SetuLink',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 12),
              const BilingualText(textKey: 'welcome_slogan', style: TextStyle(fontSize: 16)),
              const Spacer(flex: 3),
              _buildRoleButton(
                context,
                roleKey: 'user',
                onPressed: () => _navigateToLogin(context, 'citizen'),
                color: Colors.teal,
              ),
              const SizedBox(height: 20),
              _buildRoleButton(
                context,
                roleKey: 'craftizen',
                onPressed: () => _navigateToLogin(context, 'craftizen'),
                color: Colors.deepOrange,
              ),
              const Spacer(flex: 2),
              _buildRegistrationSection(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context,
      {required String roleKey,
      required VoidCallback onPressed,
      required Color color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: BilingualText(
          textKey: roleKey,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRegistrationSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const BilingualText(textKey: 'new_to_app'),
        TextButton(
          onPressed: () => _navigateToRegister(context),
          child: const BilingualText(
              textKey: 'register_now',
              style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}