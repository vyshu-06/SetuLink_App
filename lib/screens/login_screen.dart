import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/bilingual_tr.dart';
import '../widgets/custom_button.dart';
import 'phone_auth_screen.dart';
import '../services/auth_service.dart';
import '../screens/citizen_home.dart';
import '../screens/craftizen_home.dart';

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
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(btr(context, widget.role == "citizen" ? 'citizen_login' : 'craftizen_login')),
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
                  decoration: InputDecoration(labelText: btr(context, 'email')),
                  onChanged: (val) => email = val.trim(),
                  validator: (val) =>
                      (val != null && val.contains('@')) ? null : btr(context, 'enter_valid_email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'password')),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) =>
                      (val != null && val.length >= 6) ? null : btr(context, 'password_min_6'),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: btr(context, 'login'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);
                      final result = await AuthService()
                          .signInWithEmail(email, password, widget.role);
                      setState(() => loading = false);
                      if (result == null) {
                        setState(() => error = btr(context, 'login_failed'));
                      } else {
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
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  child: Text(btr(context, 'login_with_phone')),
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
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(error, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
