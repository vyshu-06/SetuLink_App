import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  late Razorpay _razorpay;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final double _defaultCommission = 10.0;
  final Map<String, double> _commissionRates = {
    'plumber': 15.0,
    'electrician': 12.0,
    'carpenter': 10.0,
  };

  PaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  double getCommissionPercent(String category) {
    return _commissionRates[category.toLowerCase()] ?? _defaultCommission;
  }

  double calculateCommission(double amount, String category) {
    final percent = getCommissionPercent(category);
    return amount * (percent / 100);
  }

  Future<void> saveTransaction({
    required String paymentId,
    required double amount,
    required String category,
    required String jobId,
    required String craftizenId,
    required String userId,
  }) async {
    final commission = calculateCommission(amount, category);
    final payout = amount - commission;

    await _db.collection('transactions').add({
      'paymentId': paymentId,
      'amount': amount,
      'commission': commission,
      'payoutAmount': payout,
      'jobId': jobId,
      'craftizenId': craftizenId,
      'userId': userId,
      'category': category,
      'status': 'completed',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void openCheckout({
    required double amount,
    required String userName,
    required String userEmail,
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
    required String category,
  }) {
    final options = {
      'key': 'YOUR_RAZORPAY_API_KEY', // Replace with your actual key
      'amount': (amount * 100).toInt(),
      'name': 'SetuLink',
      'description': '$category Service Payment',
      'prefill': {'contact': '', 'email': userEmail},
    };

    try {
      _onPaymentSuccessCallback = onSuccess;
      _onPaymentErrorCallback = onError;
      _razorpay.open(options);
    } catch (e) {
      onError(e.toString());
    }
  }

  Function(String)? _onPaymentSuccessCallback;
  Function(String)? _onPaymentErrorCallback;

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onPaymentSuccessCallback != null) _onPaymentSuccessCallback!(response.paymentId!);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onPaymentErrorCallback != null) _onPaymentErrorCallback!(response.message ?? 'Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}
}
