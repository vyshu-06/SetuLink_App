import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';

class CitizenRegisterScreen extends StatefulWidget {
  const CitizenRegisterScreen({Key? key}) : super(key: key);

  @override
  State<CitizenRegisterScreen> createState() => _CitizenRegisterScreenState();
}

class _CitizenRegisterScreenState extends State<CitizenRegisterScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Citizen Registration')),
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
                  key: const ValueKey('register_name'),
                  decoration: InputDecoration(labelText: tr('Name')),
                  onChanged: (val) => name = val.trim(),
                  validator: (val) =>
                      val == null || val.isEmpty ? tr('Enter your name') : null,
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
                  child: Text(tr('Register')),
                  onPressed: () async {
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
                        'citizen',
                        referralCode: referralCode.isNotEmpty ? referralCode : null,
                      );
                      setState(() => loading = false);
                      if (userObj == null) {
                        setState(() => errorKey = 'registration_failed_try_again');
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitizenHome(),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (loading) ...[const SizedBox(height: 18), const CircularProgressIndicator()],
                if (errorKey.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(tr(errorKey), style: const TextStyle(color: Colors.redAccent))
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}