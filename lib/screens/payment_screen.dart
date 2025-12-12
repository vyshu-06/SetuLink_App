import 'package:flutter/material.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  final String? jobId;
  final double amount;
  final String? craftizenId;
  final String category; // To determine if it's a job payment or wallet top-up

  const PaymentScreen({
    super.key,
    this.jobId,
    this.amount = 0.0,
    this.craftizenId,
    required this.category,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentService _paymentService;
  final TextEditingController _amountController = TextEditingController();
  double _finalAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _finalAmount = widget.amount;
    _amountController.text = _finalAmount > 0 ? _finalAmount.toStringAsFixed(2) : '';
    
    _amountController.addListener(() {
      setState(() {
        _finalAmount = double.tryParse(_amountController.text) ?? 0.0;
      });
    });
  }

  void _startPayment() {
    if (_finalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('enter_valid_amount'))),
      );
      return;
    }

    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You must be logged in to pay.")));
       return;
    }

    setState(() => _isLoading = true);

    _paymentService.openCheckout(
      amount: _finalAmount,
      userName: currentUser.displayName ?? 'Customer', // Use displayName which is standard User property or fallback
      userEmail: currentUser.email ?? 'customer@example.com',
      category: widget.category,
      onSuccess: (paymentId) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        _paymentService.saveTransaction(
          paymentId: paymentId,
          amount: _finalAmount,
          category: widget.category,
          jobId: widget.jobId ?? '',
          craftizenId: widget.craftizenId ?? '',
          userId: currentUser.uid,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful! ID: $paymentId')),
        );
        Navigator.pop(context); // Go back after payment
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $error')),
        );
      },
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commission = _paymentService.calculateCommission(_finalAmount, widget.category);
    final payoutAmount = _finalAmount - commission;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.category == 'wallet_topup' ? 'Add Money to Wallet' : 'pay_for_service_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              readOnly: widget.amount > 0, // Make it read-only if amount is pre-filled from a job
              decoration: InputDecoration(
                labelText: context.tr('enter_amount_inr'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.category != 'wallet_topup') ...[
              _buildPaymentDetailRow(context.tr('platform_commission'), '₹${commission.toStringAsFixed(2)}'),
              _buildPaymentDetailRow(context.tr('amount_to_craftizen'), '₹${payoutAmount.toStringAsFixed(2)}'),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(context.tr('proceed_to_pay')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
