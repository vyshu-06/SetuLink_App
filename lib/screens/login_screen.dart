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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  String email = '';
  String password = '';
  bool loading = false;
  String errorKey = ''; // Holds the translation key for the error

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    // Update email and password from controllers before validation
    email = _emailController.text.trim();
    password = _passwordController.text;

    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
        errorKey = '';
      });

      try {
        final result = await AuthService().signInWithEmail(email, password, widget.role);
        
        if (result == null) {
          // Case: Authentication successful but user document logic failed (e.g. wrong role)
          setState(() {
            loading = false;
            errorKey = 'login_failed'; // Generic failure if user role doesn't match
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
        // Debug print to see exact error code in console
        debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
        
        String newErrorKey = 'login_failed';

        if (e.code == 'user-not-found') {
           newErrorKey = 'user_not_found'; 
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
           newErrorKey = 'wrong_password'; 
        } else if (e.code == 'invalid-email') {
           newErrorKey = 'invalid_email';
        } else if (e.code == 'user-disabled') {
           newErrorKey = 'user_disabled';
        } else if (e.code == 'too-many-requests') {
           newErrorKey = 'too_many_requests';
        } else if (e.code == 'configuration-not-found') {
           newErrorKey = 'configuration_not_found';
        }
        
        setState(() {
          loading = false;
          errorKey = newErrorKey;
        });

      } catch (e) {
         debugPrint('Generic Login Error: $e');
         setState(() {
          loading = false;
          errorKey = 'login_failed';
        });
      }
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
                  controller: _emailController,
                  decoration: InputDecoration(labelText: context.tr('email')),
                  // onChanged removed, using controller
                  validator: (val) =>
                      (val != null && val.contains('@')) ? null : context.tr('enter_valid_email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  // onChanged removed, using controller
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
                  // Show actual error message if translation key missing, or use simple Text as fallback
                   Text(
                      context.tr(errorKey) == errorKey ? _getReadableError(errorKey) : context.tr(errorKey),
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to show readable error messages if translations are missing
  String _getReadableError(String key) {
    switch(key) {
      case 'user_not_found': return 'No user found with this email.';
      case 'wrong_password': return 'Incorrect password.';
      case 'invalid_email': return 'The email address is badly formatted.';
      case 'user_disabled': return 'This user has been disabled.';
      case 'too_many_requests': return 'Too many attempts. Try again later.';
      case 'configuration_not_found': return 'Authentication not configured properly. Please contact support.';
      case 'login_failed': return 'Login failed. Please check your credentials.';
      case 'registration_failed_test_user': return 'Failed to create test user.';
      default: return 'An unexpected error occurred.';
    }
  }
}
