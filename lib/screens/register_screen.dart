import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FIX: Import FirebaseAuth
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/screens/craftizen_skill_selection_screen.dart';
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import '../services/auth_service.dart';

final AnalyticsService _analyticsService = AnalyticsService();

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String confirmPwd = '';
  late String role;
  String phone = '';
  String name = '';
  String referralCode = '';
  bool loading = false;
  String errorKey = '';

  @override
  void initState() {
    super.initState();
    role = widget.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'register'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const ValueKey('register_name'),
                  decoration: InputDecoration(labelText: context.tr('name')),
                  onChanged: (val) => name = val.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? context.tr('enter_name') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('register_email'),
                  decoration: InputDecoration(labelText: context.tr('email')),
                  onChanged: (val) => email = val.trim(),
                  validator: (val) => (val != null && val.contains('@'))
                      ? null
                      : context.tr('enter_valid_email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('register_phone'),
                  decoration: InputDecoration(labelText: context.tr('phone')),
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => phone = val.trim(),
                  validator: (val) => (val != null && val.length >= 10)
                      ? null
                      : context.tr('enter_valid_phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('register_password'),
                  decoration: InputDecoration(labelText: context.tr('password')),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) => (val != null && val.length >= 6)
                      ? null
                      : context.tr('password_min_6'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('register_confirm'),
                  decoration: InputDecoration(labelText: context.tr('confirm_password')),
                  obscureText: true,
                  onChanged: (val) => confirmPwd = val,
                  validator: (val) =>
                      val != password ? context.tr('passwords_not_matching') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: context.tr('referral_code_optional')),
                  onChanged: (val) => referralCode = val.trim(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: RadioMenuButton<String>(
                        value: 'citizen',
                        groupValue: role,
                        onChanged: (val) {
                          setState(() => role = val!);
                        },
                        child: const BilingualText(textKey: 'user'),
                      ),
                    ),
                    Expanded(
                      child: RadioMenuButton<String>(
                        value: 'craftizen',
                        groupValue: role,
                        onChanged: (val) {
                          setState(() => role = val!);
                        },
                        child: const BilingualText(textKey: 'craftizen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  child: const BilingualText(textKey: 'register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        loading = true;
                        errorKey = '';
                      });

                      final authService = AuthService();
                      final User? user = await authService.registerWithEmail(
                        email,
                        password,
                        name,
                        phone,
                        role,
                        referralCode: referralCode.isNotEmpty ? referralCode : null,
                      );

                      setState(() => loading = false);

                      if (user == null) {
                        setState(() => errorKey = 'registration_failed');
                      } else {
                        await _analyticsService.logSignUp(role);
                        if (role == 'craftizen') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CraftizenSkillSelectionScreen(userId: user.uid),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const CitizenHome()),
                          );
                        }
                      }
                    }
                  },
                ),
                if (loading) ...[const SizedBox(height: 18), const CircularProgressIndicator()],
                if (errorKey.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  BilingualText(textKey: errorKey, style: const TextStyle(color: Colors.redAccent))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
