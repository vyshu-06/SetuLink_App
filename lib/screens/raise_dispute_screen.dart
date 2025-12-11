import 'package:flutter/material.dart';
import 'package:setulink_app/services/dispute_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';

class RaiseDisputeScreen extends StatefulWidget {
  final String jobId;
  final String respondentId; // The person the dispute is against

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
        throw Exception('User not logged in');
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
          SnackBar(content: Text(context.tr('dispute_raised_success'))),
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
      appBar: AppBar(title: Text(context.tr('raise_dispute'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: context.tr('reason')),
                items: [
                  'Incomplete Work',
                  'Poor Quality',
                  'Payment Issue',
                  'Behavioral Issue',
                  'Other'
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _reason = val!),
                validator: (val) => val == null ? context.tr('required_field') : null,
                // Leaving 'value' unset so 'initialValue' is implicitly null which starts empty. 
                // We rely on onChanged to update internal state for submission, but visual update is handled by the widget itself until reset.
                // To properly pre-select or control, 'value' is needed but triggers warning. 
                // Omitting 'value' fixes the warning but means we can't programmatically set selection from outside easily (not needed here).
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: context.tr('description')),
                maxLines: 4,
                onSaved: (val) => _description = val ?? '',
                validator: (val) =>
                    (val == null || val.isEmpty) ? context.tr('required_field') : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDispute,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.tr('submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
