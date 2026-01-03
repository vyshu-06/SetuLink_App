import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/craftizen_skill_selection_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';

class CraftizenRegisterScreen extends StatefulWidget {
  const CraftizenRegisterScreen({Key? key}) : super(key: key);

  @override
  State<CraftizenRegisterScreen> createState() => _CraftizenRegisterScreenState();
}

class _CraftizenRegisterScreenState extends State<CraftizenRegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String confirmPwd = '';
  String phone = '';
  String name = '';
  String referralCode = '';
  bool loading = false;
  String errorKey = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(tr('Craftizen Registration')),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        children: [
                          Text(
                            tr('Create Craftizen Account'), // New Key
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('register_name'),
                            decoration: InputDecoration(labelText: tr('Name')),
                            onChanged: (val) => name = val.trim(),
                            validator: (val) =>
                                val == null || val.isEmpty ? tr('Enter your Name') : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register_email'),
                            decoration: InputDecoration(labelText: tr('Email')),
                            onChanged: (val) => email = val.trim(),
                            validator: (val) => (val != null && val.contains('@'))
                                ? null
                                : tr('Enter your valid Email'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register_phone'),
                            decoration: InputDecoration(labelText: tr('Phone Number')),
                            keyboardType: TextInputType.phone,
                            onChanged: (val) => phone = val.trim(),
                            validator: (val) => (val != null && val.length >= 10)
                                ? null
                                : tr('Enter your valid Phone Number'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register_password'),
                            decoration: InputDecoration(
                              labelText: tr('Password'),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            onChanged: (val) => password = val,
                            validator: (val) => (val != null && val.length >= 6)
                                ? null
                                : tr('Password should have minimum of 6 characters'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register_confirm'),
                            decoration: InputDecoration(
                              labelText: tr('Confirm Password'),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            onChanged: (val) => confirmPwd = val,
                            validator: (val) =>
                                val != password ? tr('Password do not match') : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(labelText: tr('Referral Code(Optional)')),
                            onChanged: (val) => referralCode = val.trim(),
                          ),
                          const SizedBox(height: 26),
                          ElevatedButton(
                            child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(tr('Register')),
                            onPressed: loading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  loading = true;
                                  errorKey = '';
                                });
                                final userObj = await AuthService().registerWithEmail(
                                  email,
                                  password,
                                  name,
                                  phone,
                                  'craftizen',
                                  referralCode: referralCode.isNotEmpty ? referralCode : null,
                                );
                                if (!mounted) return;
                                setState(() => loading = false);
                                if (userObj == null) {
                                  setState(() => errorKey = 'registration_failed_try_again');
                                } else {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CraftizenSkillSelectionScreen(userId: userObj.uid),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          if (errorKey.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(tr(errorKey), style: const TextStyle(color: Colors.redAccent))
                          ]
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
