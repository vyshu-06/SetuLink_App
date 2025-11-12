import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/bilingual_tr.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'citizen_home.dart';
import 'craftizen_home.dart';

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
  bool loading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    role = widget.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(btr(context, 'register')),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'name')),
                  onChanged: (val) => name = val.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? btr(context, 'enter_name') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'email')),
                  onChanged: (val) => email = val.trim(),
                  validator: (val) => (val != null && val.contains('@'))
                      ? null
                      : btr(context, 'enter_valid_email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'phone')),
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => phone = val.trim(),
                  validator: (val) => (val != null && val.length >= 10)
                      ? null
                      : btr(context, 'enter_valid_phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'password')),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) => (val != null && val.length >= 6)
                      ? null
                      : btr(context, 'password_min_6'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: btr(context, 'confirm_password')),
                  obscureText: true,
                  onChanged: (val) => confirmPwd = val,
                  validator: (val) =>
                      val != password ? btr(context, 'passwords_not_matching') : null,
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
                        child: Text(btr(context, 'user')),
                      ),
                    ),
                    Expanded(
                      child: RadioMenuButton<String>(
                        value: 'craftizen',
                        groupValue: role,
                        onChanged: (val) {
                          setState(() => role = val!);
                        },
                        child: Text(btr(context, 'craftizen')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                CustomButton(
                  text: btr(context, 'register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => loading = true);
                      final userObj = await AuthService().registerWithEmail(
                        email,
                        password,
                        name,
                        phone,
                        role,
                      );
                      setState(() => loading = false);
                      if (userObj == null) {
                        setState(() => error = btr(context, 'registration_failed'));
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => role == 'citizen'
                                ? const CitizenHome()
                                : const CraftizenHome(),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (loading) ...[const SizedBox(height: 18), const CircularProgressIndicator()],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(error, style: const TextStyle(color: Colors.redAccent))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
