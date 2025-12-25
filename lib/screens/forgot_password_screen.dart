import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  bool loading = false;
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('forgot_password'))),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => loading = true);
                    await context.read<AuthService>().sendPasswordResetEmail(email);
                    if (!mounted) return;
                    setState(() => loading = false);
                    setState(() => message = tr('password_reset_email_sent'));
                  }
                },
                child: Text(tr('send_reset_email')),
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(message, style: const TextStyle(color: Colors.green), textAlign: TextAlign.center),
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
