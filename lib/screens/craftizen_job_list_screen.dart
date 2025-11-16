import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class CraftizenJobListScreen extends StatefulWidget {
  const CraftizenJobListScreen({Key? key}) : super(key: key);

  @override
  State<CraftizenJobListScreen> createState() => _CraftizenJobListScreenState();
}

class _CraftizenJobListScreenState extends State<CraftizenJobListScreen> {
  final AuthService _authService = AuthService();
  bool _isKycVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkKycStatus();
  }

  Future<void> _checkKycStatus() async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser['uid']).get();
      if (userDoc.exists) {
        final kycData = userDoc.data()?['kyc'];
        if (kycData != null && kycData['verified'] == true) {
          setState(() {
            _isKycVerified = true;
          });
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'job_requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isKycVerified
              ? _buildJobList()
              : _buildKycNotVerifiedWarning(),
    );
  }

  Widget _buildJobList() {
    // Replace with actual job list implementation
    return const Center(
      child: BilingualText(textKey: 'no_jobs_available'),
    );
  }

  Widget _buildKycNotVerifiedWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning, size: 60, color: Colors.orange),
            SizedBox(height: 16),
            BilingualText(
              textKey: 'kyc_not_verified_message',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
