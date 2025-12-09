import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  final String role;
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
      appBar: AppBar(title: Text(tr('login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: tr('email')),
                onChanged: (val) => email = val,
                validator: (val) => val!.isEmpty ? tr('enter_email') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: tr('password')),
                obscureText: true,
                onChanged: (val) => password = val,
                validator: (val) => val!.length < 6 ? tr('password_min_6') : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);
                    final result = await context.read<AuthService>().signInWithEmail(email, password);
                    if (!mounted) return;
                    setState(() => loading = false);
                    if (result == null) {
                      setState(() => error = tr('login_failed'));
                    } else {
                      final route = widget.role == 'citizen' ? '/citizen_home' : '/craftizen_home';
                      Navigator.of(context).pushReplacementNamed(route);
                    }
                  }
                },
                child: Text(tr('login')),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
