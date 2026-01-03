import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class PhoneAuthScreen extends StatefulWidget {
  final String role;
  const PhoneAuthScreen({required this.role, Key? key}) : super(key: key);

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendOtp(BuildContext context) async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    await authService.sendOtp(
      _phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await authService.signInWithCredential(credential);
        if (mounted) _navigateToHome(context);
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: ${e.message}')));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  void _verifyOtp(BuildContext context) async {
    if (_verificationId == null || _otpController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final user = await authService.verifyOtp(_verificationId!, _otpController.text.trim());

    if (mounted) setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) _navigateToHome(context);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  void _navigateToHome(BuildContext context) {
    final route = widget.role == 'citizen' ? '/citizen_home' : '/craftizen_home';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'phone_sign_in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _codeSent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: _buildPhoneInput(),
                      secondChild: _buildOtpInput(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BilingualText(textKey: 'enter_phone_number', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const BilingualText(textKey: 'we_will_send_otp', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: tr('phone_number'), prefixText: '+91 '),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _sendOtp(context),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const BilingualText(textKey: 'send_otp'),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BilingualText(textKey: 'enter_otp', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(tr('otp_sent_to', args: [_phoneController.text]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 24),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr('otp')),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _verifyOtp(context),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const BilingualText(textKey: 'verify_otp'),
        ),
        TextButton(
          onPressed: () => setState(() => _codeSent = false),
          child: const BilingualText(textKey: 'change_number'),
        ),
      ],
    );
  }
}
