import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'phone_auth_screen.dart';
import '../services/auth_service.dart';
import '../screens/citizen_home.dart';
import '../screens/craftizen_home.dart';

final AnalyticsService _analyticsService = AnalyticsService();

class LoginScreen extends StatefulWidget {
  final String role; // "citizen" or "craftizen"
  const LoginScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  String errorKey = ''; // Holds the translation key for the error

  @override
  void initState() {
    super.initState();
    // Set default test credentials
    if (widget.role == 'citizen') {
      email = 'citizen@test.com';
    } else {
      email = 'craftizen@test.com';
    }
    password = 'password123';
  }

  Future<void> _attemptLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
        errorKey = '';
      });

      try {
        final result = await AuthService().signInWithEmail(email, password, widget.role);
        
        if (result == null) {
          setState(() {
            loading = false;
            errorKey = 'login_failed';
          });
        } else {
          await _analyticsService.logLogin(widget.role);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => widget.role == 'citizen'
                    ? const CitizenHome()
                    : const CraftizenHome(),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // If user not found and it's a test user, try to register automatically
          if ((email == 'citizen@test.com' || email == 'craftizen@test.com') && password == 'password123') {
            await _attemptAutoRegister();
          } else {
             setState(() {
              loading = false;
              errorKey = 'login_failed';
            });
          }
        } else {
           setState(() {
            loading = false;
            errorKey = 'login_failed';
          });
        }
      } catch (e) {
         setState(() {
          loading = false;
          errorKey = 'login_failed';
        });
      }
    }
  }

  Future<void> _attemptAutoRegister() async {
    try {
       final result = await AuthService().registerWithEmail(
        email,
        password,
        widget.role == 'citizen' ? 'Test Citizen' : 'Test Craftizen',
        '+910000000000',
        widget.role,
      );

      if (result != null) {
          await _analyticsService.logLogin(widget.role); // Log as login after registration
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => widget.role == 'citizen'
                    ? const CitizenHome()
                    : const CraftizenHome(),
              ),
            );
          }
      } else {
        setState(() {
          loading = false;
          errorKey = 'registration_failed_test_user';
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorKey = 'registration_failed_test_user';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BilingualText(textKey: widget.role == "citizen" ? 'citizen_login' : 'craftizen_login'),
        backgroundColor: widget.role == 'citizen' ? Colors.teal : Colors.deepOrange,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(labelText: context.tr('email')),
                  onChanged: (val) => email = val.trim(),
                  validator: (val) =>
                      (val != null && val.contains('@')) ? null : context.tr('enter_valid_email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: password,
                  decoration: InputDecoration(labelText: context.tr('password')),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) =>
                      (val != null && val.length >= 6) ? null : context.tr('password_min_6'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  child: const BilingualText(textKey: 'login'),
                  onPressed: _attemptLogin,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  child: const BilingualText(textKey: 'login_with_phone'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhoneAuthScreen(role: widget.role),
                      ),
                    );
                  },
                ),
                if (loading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
                if (errorKey.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  BilingualText(textKey: errorKey, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
