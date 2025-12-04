import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:easy_localization/easy_localization.dart';

class SubscriptionScreen extends StatefulWidget {
  final String planId;

  const SubscriptionScreen({required this.planId, super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Razorpay _razorpay;
  String? _subscriptionId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _createSubscription();
  }

  Future<void> _createSubscription() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createSubscription');
      final result = await callable.call(<String, dynamic>{
        'plan_id': widget.planId,
        'total_count': 12,
      });
      
      if (!mounted) return;
      
      setState(() {
        _subscriptionId = result.data['id'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error')}: $e')),
      );
    }
  }

  void _openCheckout() {
    if (_subscriptionId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('subscription_not_ready'))));
      return;
    }

    var options = {
      'key': 'YOUR_RAZORPAY_API_KEY', // Replace with your actual key
      'subscription_id': _subscriptionId,
      'name': 'SetuLink',
      'description': context.tr('subscription_payment_description'),
      'prefill': {'email': 'user@example.com', 'contact': '9999999999'}, // Replace with actual user data
      'retry': {'enabled': true, 'max_count': 3},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifySubscriptionSignature');
      final verifyRes = await callable.call(<String, dynamic>{
        'razorpay_payment_id': response.paymentId,
        'razorpay_subscription_id': _subscriptionId, 
        'razorpay_signature': response.signature,
      });

      if (!mounted) return;

      if (verifyRes.data['verified'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('subscription_payment_verified'))));
        // TODO: Update Firestore user subscription status here
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('subscription_verification_failed'))));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('verification_error')}: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${context.tr('payment_failed')}: ${response.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(context.tr('subscribe_title'))),
        body: Center(
          child: _subscriptionId == null
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _openCheckout,
                  child: Text(context.tr('subscribe_now')),
                ),
        ));
  }
}
