import 'package:flutter/material.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/price_calculator_service.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

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

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late PaymentService _paymentService;
  final TextEditingController _amountController = TextEditingController();
  double _finalAmount = 0.0;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commission = PriceCalculatorService.getCommission(_finalAmount);
    final payoutAmount = _finalAmount - commission;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: BilingualText(
          textKey: widget.category == 'wallet_topup' ? 'add_money_to_wallet' : 'pay_for_service',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              readOnly: widget.amount > 0,
                              decoration: InputDecoration(
                                labelText: tr('amount_inr'),
                                border: const UnderlineInputBorder(),
                              ),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.category != 'wallet_topup') ...[
                              const SizedBox(height: 20),
                              _buildPaymentDetailRow(tr('platform_commission'), '₹${commission.toStringAsFixed(2)}'),
                              const Divider(height: 20),
                              _buildPaymentDetailRow(tr('craftizen_payout'), '₹${payoutAmount.toStringAsFixed(2)}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _startPayment,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : BilingualText(textKey: 'proceed_to_pay', style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
      ],
    );
  }
}
