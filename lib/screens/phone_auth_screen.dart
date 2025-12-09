import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role;
  const PhoneAuthScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext context) async {
    final authService = context.read<AuthService>();
    await authService.sendOtp(
      _phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await authService.signInWithCredential(credential);
        _navigateToHome(context);
      },
      verificationFailed: (e) {},
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  void _verifyOtp(BuildContext context) async {
    if (_verificationId == null) return;
    final authService = context.read<AuthService>();
    final user = await authService.verifyOtp(_verificationId!, _otpController.text.trim());
    if (user != null) {
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    final route = widget.role == 'citizen' ? '/citizen_home' : '/craftizen_home';
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('phone_sign_in'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_codeSent)
              TextField(controller: _phoneController, decoration: InputDecoration(labelText: tr('phone_number')))
            else
              TextField(controller: _otpController, decoration: const InputDecoration(labelText: 'OTP')),
            ElevatedButton(
              onPressed: () => _codeSent ? _verifyOtp(context) : _sendOtp(context),
              child: Text(_codeSent ? tr('verify_otp') : tr('send_otp')),
            ),
          ],
        ),
      ),
    );
  }
}
