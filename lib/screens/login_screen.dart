import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/screens/craftizen_home.dart';
import 'package:setulink_app/screens/phone_auth_screen.dart';
import 'package:setulink_app/screens/forgot_password_screen.dart';
import 'package:setulink_app/screens/admin_dashboard_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart'; // Import bilingual text widget
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;
  const LoginScreen({Key? key, this.initialRole = 'citizen'}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  String error = '';
  bool _obscureText = true;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    // Pre-fill for demonstration purposes, matching the image
    email = 'citizen@test.com';
    password = 'password123';
  }

  String _getTitleKey() {
    switch (_selectedRole) {
      case 'citizen':
        return 'citizen_login';
      case 'craftizen':
        return 'craftizen_login';
      case 'admin':
        return 'admin_login'; // Assuming you have this key
      default:
        return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BilingualText(textKey: _getTitleKey()),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Email Field
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  border: const UnderlineInputBorder(),
                ),
                onChanged: (val) => email = val,
                validator: (val) => val!.isEmpty ? 'enter_valid_email'.tr() : null,
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                initialValue: password,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                obscureText: _obscureText,
                onChanged: (val) => password = val,
                validator: (val) => val!.length < 6 ? 'password_min_6'.tr() : null,
              ),
              const SizedBox(height: 40),

              // Login Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);

                    if (_selectedRole == 'admin') {
                      if (email == 'admin@setulink.com' && password == 'admin123') {
                        Navigator.pushReplacementNamed(context, '/admin');
                        setState(() => loading = false);
                        return;
                      }
                    }

                    final result = await context.read<AuthService>().signInWithEmail(email, password);
                    if (!mounted) return;
                    setState(() => loading = false);

                    if (result == null) {
                      setState(() => error = 'Login failed.\n(cloud_firestore/unavailable) Failed to get document because the client is offline.');
                    } else {
                      if (_selectedRole == 'citizen') {
                        Navigator.of(context).pushReplacementNamed('/citizen_home');
                      } else if (_selectedRole == 'craftizen') {
                        Navigator.of(context).pushReplacementNamed('/craftizen_home');
                      } else if (_selectedRole == 'admin') {
                        Navigator.of(context).pushReplacementNamed('/admin');
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0), 
                  foregroundColor: Colors.black, 
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const BilingualText(textKey: 'login'),
              ),
              const SizedBox(height: 16),

              // Login with Phone Button
              OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneAuthScreen(role: _selectedRole)));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const BilingualText(textKey: 'login_with_phone'),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Loading Indicator
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
