import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingVerificationScreen extends StatefulWidget {
  final String userId;
  final Map<String, String> commonAnswers;
  final List<String> passedSkills;
  final Map<String, String> videoUrls;

  const PendingVerificationScreen({
    Key? key,
    required this.userId,
    this.commonAnswers = const {},
    this.passedSkills = const [],
    this.videoUrls = const {},
  }) : super(key: key);

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveKycData();
  }

  Future<void> _saveKycData() async {
    // If no new data to save, assume it's already saved
    if (widget.commonAnswers.isEmpty && widget.passedSkills.isEmpty && widget.videoUrls.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final kycData = {
        'commonAnswers': widget.commonAnswers,
        'passedSkills': widget.passedSkills,
        'videoUrls': widget.videoUrls,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'kyc': kycData});
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('verification_pending')),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSaving
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
                    const SizedBox(height: 24),
                    Text(
                      tr('kyc_under_verification'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('kyc_verification_message'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Text(tr('back_to_home')),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
