import 'package:flutter/material.dart';
import 'package:setulink_app/services/dispute_service.dart';

class RaiseDisputeScreen extends StatefulWidget {
  final String jobId;
  final String craftizenId;
  final String userId;

  const RaiseDisputeScreen({
    Key? key,
    required this.jobId,
    required this.craftizenId,
    required this.userId,
  }) : super(key: key);

  @override
  _RaiseDisputeScreenState createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  String _disputeType = 'quality';
  final _descriptionController = TextEditingController();
  final DisputeService _disputeService = DisputeService();
  bool _isLoading = false;

  Future<void> _submitDispute() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _disputeService.createDispute(
        jobId: widget.jobId,
        raisedBy: widget.userId,
        craftizenId: widget.craftizenId,
        type: _disputeType,
        description: _descriptionController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute raised successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error raising dispute: $e')),
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
        title: const Text('Raise a Dispute'),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _disputeType, 
              items: ['quality', 'payment', 'other']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e[0].toUpperCase() + e.substring(1)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                _disputeType = val!;
              }),
              decoration: const InputDecoration(
                labelText: 'Dispute Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe your issue',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDispute,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Dispute', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
