import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/payout_service.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:setulink_app/screens/job_summary_screen.dart';
import 'package:setulink_app/screens/earnings_screen.dart';
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
  final PayoutService _payoutService = PayoutService();
  final PaymentService _paymentService = PaymentService();

  void _handleCollectCash() async {
    if (widget.job.assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Job has no assigned worker')));
      return;
    }

    setState(() => _isProcessing = true);
    
    final category = widget.job.requiredSkills.isNotEmpty ? widget.job.requiredSkills.first : 'general';
    final commission = _paymentService.calculateCommission(widget.job.budget, category);

    try {
      await _payoutService.processJobPayment(
        jobId: widget.job.id,
        craftizenId: widget.job.assignedTo!,
        userId: widget.job.userId,
        amount: widget.job.budget,
        category: category,
        isCash: true,
        commission: commission,
      );
      _navigateToSummary();
    } catch (e) {
      setState(() => _isProcessing = false);
      final errorStr = e.toString();
      if (errorStr.contains('INSUFFICIENT_BALANCE')) {
        _showLowBalanceDialog(commission);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $errorStr')));
      }
    }
  }

  void _showLowBalanceDialog(double requiredCommission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const BilingualText(textKey: 'Insufficient Balance'),
        content: Text('Your wallet balance is insufficient to pay the platform commission of ₹${requiredCommission.toStringAsFixed(2)}. Please recharge your wallet to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const BilingualText(textKey: 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
            },
            child: const BilingualText(textKey: 'Recharge'),
          ),
        ],
      ),
    );
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
              if (widget.job.assignedTo == null) return;
              
              setState(() => _isProcessing = true);
              
              final category = widget.job.requiredSkills.isNotEmpty ? widget.job.requiredSkills.first : 'general';
              final commission = _paymentService.calculateCommission(widget.job.budget, category);

              try {
                await _payoutService.processJobPayment(
                  jobId: widget.job.id,
                  craftizenId: widget.job.assignedTo!,
                  userId: widget.job.userId,
                  amount: widget.job.budget,
                  category: category,
                  isCash: false,
                  paymentId: 'QR_MOCK_${DateTime.now().millisecondsSinceEpoch}',
                  commission: commission,
                );
                _navigateToSummary();
              } catch (e) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
              }
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
