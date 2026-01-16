import 'package:flutter/material.dart';
import 'package:setulink_app/services/dispute_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class RaiseDisputeScreen extends StatefulWidget {
  final String jobId;
  final String respondentId;

  const RaiseDisputeScreen({
    required this.jobId,
    required this.respondentId,
    Key? key,
  }) : super(key: key);

  @override
  State<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _reason = '';
  String _description = '';
  bool _isLoading = false;
  final DisputeService _disputeService = DisputeService();

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final currentUser = AuthService().getCurrentUser();
      if (currentUser == null) {
        throw Exception(tr('login_failed'));
      }

      await _disputeService.raiseDispute(
        jobId: widget.jobId,
        raiserId: currentUser.uid,
        respondentId: widget.respondentId,
        reason: _reason,
        description: _description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'yes'), // Placeholder for Raise Dispute
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BilingualText(
                textKey: 'tagline', // Placeholder
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  label: BilingualText(textKey: 'service'), // Placeholder for Reason
                  border: OutlineInputBorder(),
                ),
                items: [
                  'incomplete_work',
                  'poor_quality',
                  'payment_issue',
                  'behavioral_issue',
                  'other'
                ].map((key) => DropdownMenuItem(value: key, child: BilingualText(textKey: key))).toList(),
                onChanged: (val) => setState(() => _reason = val!),
                validator: (val) => val == null ? tr('please_select_option') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  label: BilingualText(textKey: 'description'),
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onSaved: (val) => _description = val ?? '',
                validator: (val) => (val == null || val.isEmpty) ? tr('please_enter_value') : null,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50)
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const BilingualText(textKey: 'complete'), // Placeholder for Submit
              ),
            ],
          ),
        ),
      ),
    );
  }
}
