import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/screens/job_summary_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class CollectPaymentScreen extends StatefulWidget {
  final JobModel job;

  const CollectPaymentScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  bool _isProcessing = false;

  void _handleCollectCash() async {
    setState(() => _isProcessing = true);
    await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
      'paymentMethod': 'cash',
      'paymentStatus': 'paid',
    });
    _navigateToSummary();
  }

  void _handleScanQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const BilingualText(textKey: 'Scan QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 200, color: Colors.black87),
            const SizedBox(height: 16),
            const Text('Please scan this QR to pay to SetuLink'),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Waiting for payment confirmation...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isProcessing = true);
              await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
                'paymentMethod': 'qr_scan',
                'paymentStatus': 'paid',
              });
              _navigateToSummary();
            },
            child: const Text('Mock Success'),
          ),
        ],
      ),
    );
  }

  void _navigateToSummary() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => JobSummaryScreen(jobId: widget.job.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'Collect Payment'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amount to Collect: ₹${widget.job.budget}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleScanQR,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _handleCollectCash,
              icon: const Icon(Icons.money),
              label: const Text('Collect Cash'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
