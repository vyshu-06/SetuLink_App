import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/phone_auth_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final String initialRole;
  const LoginScreen({Key? key, this.initialRole = 'citizen'}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  String error = '';
  bool _obscureText = true;
  late String _selectedRole;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTitleKey() {
    switch (_selectedRole) {
      case 'citizen':
        return 'citizen_login';
      case 'craftizen':
        return 'craftizen_login';
      case 'admin':
        return 'admin_login';
      default:
        return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: BilingualText(textKey: _getTitleKey()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.8),
              AppColors.accentColor.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tr('welcome_back'), // Assuming you have a key like this
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: email,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(labelText: 'email'.tr()),
                            onChanged: (val) => email = val,
                            validator: (val) => val!.isEmpty ? 'enter_valid_email'.tr() : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            initialValue: password,
                            enableSuggestions: false,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'password'.tr(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                                onPressed: () {
                                  setState(() => _obscureText = !_obscureText);
                                },
                              ),
                            ),
                            obscureText: _obscureText,
                            onChanged: (val) => password = val,
                            validator: (val) => val!.length < 6 ? 'password_min_6'.tr() : null,
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            child: loading ? const CircularProgressIndicator(color: Colors.white) : const BilingualText(textKey: 'login'),
                            onPressed: loading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => loading = true);
                                if (_selectedRole == 'admin') {
                                  if (email == 'admin@setulink.com' && password == 'admin123') {
                                    Navigator.pushReplacementNamed(context, '/admin');
                                    if(mounted) setState(() => loading = false);
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
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneAuthScreen(role: _selectedRole)));
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const BilingualText(textKey: 'login_with_phone'),
                          ),
                          if (error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 24.0),
                              child: Text(
                                error,
                                style: const TextStyle(color: AppColors.errorColor, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
