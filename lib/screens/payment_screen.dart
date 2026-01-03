import 'package:flutter/material.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/price_calculator_service.dart';

// Final, corrected version of the PaymentScreen.
class PaymentScreen extends StatefulWidget {
  final String? jobId;
  final double amount;
  final String? craftizenId;
  final String category;

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
    // The amount is passed directly to the screen. No calculation is needed here.
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
        SnackBar(content: Text(tr('Enter a valid amount'))),
      );
      return;
    }

    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr("You must be logged in to pay"))));
      return;
    }

    setState(() => _isLoading = true);

    _paymentService.openCheckout(
      amount: _finalAmount,
      userName: currentUser.displayName ?? 'Customer',
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
          SnackBar(content: Text('${tr('Payment Successful Id')}: $paymentId')),
        );
        Navigator.pop(context);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('Payment Failed')}: $error')),
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
    // The only call to PriceCalculatorService is for the commission, which is correct.
    final commission = PriceCalculatorService.getCommission(_finalAmount);
    final payoutAmount = _finalAmount - commission;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: Text(tr(widget.category == 'Wallet topup' ? 'Add money to the Wallet' : 'Pay for service title'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              readOnly: widget.amount > 0,
              decoration: InputDecoration(
                labelText: tr('Enter a amount(INR)'),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),
            if (widget.category != 'wallet_topup') ...[
              _buildPaymentDetailRow(tr('Platform Commission'), '₹\${commission.toStringAsFixed(2)}'),
              _buildPaymentDetailRow(tr('Amount to Craftizen'), '₹\${payoutAmount.toStringAsFixed(2)}'),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _startPayment,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(tr('Proceed to pay')),
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
