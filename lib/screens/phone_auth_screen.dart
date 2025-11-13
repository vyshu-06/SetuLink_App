import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
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
  String _errorKey = '';

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+918121127978'; // Default for testing
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorKey = '';
    });
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
            _errorKey = e.code;
            _loading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorKey = 'unexpected_error';
        _loading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate() || _verificationId == null) return;
    setState(() {
      _loading = true;
      _errorKey = '';
    });
    try {
      await _authService.verifyOtp(_verificationId!, _otpController.text.trim(), widget.role);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorKey = e.code;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorKey = 'unexpected_error';
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
        title: const BilingualText(textKey: 'phone_login'),
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
                    decoration: InputDecoration(labelText: context.tr('phone_number')),
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        val == null || val.length < 10 ? context.tr('enter_valid_phone') : null,
                  ),
                if (_otpSent)
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: context.tr('enter_otp')),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.length < 6 ? context.tr('enter_valid_otp') : null,
                  ),
                const SizedBox(height: 20),
                if (_loading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    child: BilingualText(textKey: _otpSent ? 'verify_otp' : 'send_otp'),
                    onPressed: _otpSent ? _verifyOtp : _sendOtp,
                  ),
                if (_errorKey.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: BilingualText(
                      textKey: _errorKey,
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
