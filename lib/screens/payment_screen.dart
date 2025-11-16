import 'package:flutter/material.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentScreen extends StatefulWidget {
  final String category;

  const PaymentScreen({required this.category, Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _amountController = TextEditingController();
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      setState(() {
        _amount = double.tryParse(_amountController.text) ?? 0.0;
      });
    });
  }

  void _startPayment() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('enter_valid_amount'))),
      );
      return;
    }

    _paymentService.openCheckout(
      amount: _amount,
      userName: 'Customer Name', // Replace with actual user data
      userEmail: 'customer@example.com', // Replace with actual user data
      category: widget.category,
      onSuccess: (paymentId) {
        _paymentService.saveTransaction(
          paymentId: paymentId,
          amount: _amount,
          category: widget.category,
          jobId: 'your_job_id', // Replace with actual job ID
          craftizenId: 'craftizen_id', // Replace with actual craftizen ID
          userId: 'user_id', // Replace with actual user ID
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful! ID: $paymentId')),
        );
      },
      onError: (error) {
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
    final commission = _paymentService.calculateCommission(_amount, widget.category);
    final payoutAmount = _amount - commission;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pay_for_service_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.tr('enter_amount_inr')),
            ),
            const SizedBox(height: 20),
            Text('${context.tr('platform_commission')}: ₹${commission.toStringAsFixed(2)} (${_paymentService.getCommissionPercent(widget.category)}%)'),
            Text('${context.tr('amount_to_craftizen')}: ₹${payoutAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startPayment,
              child: Text(context.tr('proceed_to_pay')),
            ),
          ],
        ),
      ),
    );
  }
}
