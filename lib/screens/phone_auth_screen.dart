import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/bilingual_tr.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'citizen_home.dart';
import 'craftizen_home.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role;
  const PhoneAuthScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+918121127978';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.sendOtp(
        _phoneController.text.trim(),
        codeSent: (verificationId, forceResendingToken) {
          setState(() {
            _otpSent = true;
            _verificationId = verificationId;
            _loading = false;
          });
        },
        verificationCompleted: (credential) async {
          await _authService.signInWithCredential(credential, widget.role);
          _navigateToHome();
        },
        verificationFailed: (e) {
          setState(() {
            _error = e.message ?? 'Failed to send OTP';
            _loading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate() || _verificationId == null) return;
    setState(() => _loading = true);
    try {
      await _authService.verifyOtp(_verificationId!, _otpController.text.trim(), widget.role);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Invalid OTP';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => widget.role == 'citizen' ? const CitizenHome() : const CraftizenHome(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(btr(context, 'phone_login')),
        backgroundColor: widget.role == 'citizen' ? Colors.teal : Colors.deepOrange,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (!_otpSent)
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: btr(context, 'phone_number')),
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        val == null || val.length < 10 ? btr(context, 'enter_valid_phone') : null,
                  ),
                if (_otpSent)
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: btr(context, 'enter_otp')),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.length < 6 ? btr(context, 'enter_valid_otp') : null,
                  ),
                const SizedBox(height: 20),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  CustomButton(
                    text: _otpSent ? btr(context, 'verify_otp') : btr(context, 'send_otp'),
                    onPressed: _otpSent ? _verifyOtp : _sendOtp,
                  ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
