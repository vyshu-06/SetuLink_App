import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text(tr('register'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: tr('name')),
                  onChanged: (val) => name = val.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? tr('enter_name') : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: tr('email')),
                  onChanged: (val) => email = val.trim(),
                  validator: (val) => (val != null && val.contains('@'))
                      ? null
                      : tr('enter_valid_email'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: tr('phone')),
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => phone = val.trim(),
                  validator: (val) => (val != null && val.length >= 10)
                      ? null
                      : tr('enter_valid_phone'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: tr('password')),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) => (val != null && val.length >= 6)
                      ? null
                      : tr('password_min_6'),
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: tr('confirm_password')),
                  obscureText: true,
                  onChanged: (val) => confirmPwd = val,
                  validator: (val) =>
                      val != password ? tr('passwords_not_matching') : null,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(tr('citizen')),
                        leading: Radio<String>(
                          value: 'citizen',
                          groupValue: role,
                          onChanged: (val) {
                            setState(() => role = val!);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(tr('craftizen')),
                        leading: Radio<String>(
                          value: 'craftizen',
                          groupValue: role,
                          onChanged: (val) {
                            setState(() => role = val!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 26),
                CustomButton(
                  text: tr('register'),
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
                        setState(() => error = tr('registration_failed'));
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
                if (loading) ...[SizedBox(height: 18), CircularProgressIndicator()],
                if (error.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(error, style: TextStyle(color: Colors.redAccent))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}