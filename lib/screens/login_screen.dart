import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Added to access Firebase.app()
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'phone_auth_screen.dart';
import '../services/auth_service.dart';
import '../screens/citizen_home.dart';
import '../screens/craftizen_home.dart';
import '../screens/admin_dashboard_screen.dart'; // Import Admin Dashboard

final AnalyticsService _analyticsService = AnalyticsService();

class LoginScreen extends StatefulWidget {
  final String role; // "citizen" or "craftizen" or "admin"
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
  String errorKey = ''; 
  String rawErrorMessage = ''; // To show detailed error if needed

  @override
  void initState() {
    super.initState();
    // Removed pre-filled credentials
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    email = _emailController.text.trim();
    password = _passwordController.text;

    if (_formKey.currentState!.validate()) {
      setState(() {
        loading = true;
        errorKey = '';
        rawErrorMessage = '';
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
            // Handle navigation based on role
            Widget destination;
            if (widget.role == 'citizen') {
              destination = const CitizenHome();
            } else if (widget.role == 'craftizen') {
              destination = const CraftizenHome();
            } else if (widget.role == 'admin') {
              destination = const AdminDashboardScreen();
            } else {
              // Fallback
              destination = const CitizenHome();
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
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
          // Store raw message for specific errors to help debugging
          rawErrorMessage = '${e.code}: ${e.message}';
        });

      } catch (e) {
         debugPrint('Generic Login Error: $e');
         setState(() {
          loading = false;
          errorKey = 'login_failed';
          rawErrorMessage = e.toString();
        });
      }
    }
  }

  void _showConfigDebugDialog() {
    try {
      final options = Firebase.app().options;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Firebase Config Debug'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('App ID: ${options.appId}'),
                const SizedBox(height: 8),
                Text('API Key: ${options.apiKey}'),
                const SizedBox(height: 8),
                Text('Project ID: ${options.projectId}'),
                const SizedBox(height: 8),
                Text('Auth Domain: ${options.authDomain}'),
                const SizedBox(height: 16),
                const Text('Compare these with your Firebase Console > Project Settings.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
       showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text('Could not read config: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleKey;
    Color appColor;

    if (widget.role == 'citizen') {
      titleKey = 'citizen_login';
      appColor = Colors.teal;
    } else if (widget.role == 'craftizen') {
      titleKey = 'craftizen_login';
      appColor = Colors.deepOrange;
    } else {
      titleKey = 'Admin Login'; // Assuming translation key or direct text
      appColor = Colors.blueGrey;
    }

    return Scaffold(
      appBar: AppBar(
        title: widget.role == 'admin' 
            ? const Text('Admin Login') 
            : BilingualText(textKey: titleKey),
        backgroundColor: appColor,
        actions: [
          // Debug button to verify config loaded in browser
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showConfigDebugDialog,
            tooltip: 'Debug Config',
          )
        ],
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
                  validator: (val) =>
                      (val != null && val.length >= 6) ? null : context.tr('password_min_6'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  child: const BilingualText(textKey: 'login'),
                  onPressed: _attemptLogin,
                ),
                const SizedBox(height: 12),
                if (widget.role != 'admin') // Only show phone login for regular users
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
                   Text(
                      _getReadableError(errorKey),
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    if (errorKey == 'configuration_not_found' || errorKey == 'login_failed')
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '($rawErrorMessage)',
                          style: const TextStyle(color: Colors.red, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getReadableError(String key) {
    switch(key) {
      case 'user_not_found': return 'No user found with this email.';
      case 'wrong_password': return 'Incorrect password.';
      case 'invalid_email': return 'The email address is badly formatted.';
      case 'user_disabled': return 'This user has been disabled.';
      case 'too_many_requests': return 'Too many attempts. Try again later.';
      case 'configuration_not_found': return 'Firebase Config Error (See below).';
      case 'login_failed': return 'Login failed.';
      case 'registration_failed_test_user': return 'Failed to create test user.';
      default: return context.tr(key);
    }
  }
}
