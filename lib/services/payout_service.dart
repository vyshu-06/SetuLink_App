import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTransactions(String userId, {bool isCraftizen = false}) {
    return _db.collection('transactions')
        .where(isCraftizen ? 'craftizenId' : 'userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<double> getWalletBalance(String userId) async {
    final doc = await _db.collection('wallets').doc(userId).get();
    if (!doc.exists) return 0.0;
    return (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
  }

  Stream<DocumentSnapshot> getWalletStream(String userId) {
    return _db.collection('wallets').doc(userId).snapshots();
  }

  Future<void> rechargeWallet(String userId, double amount, String paymentId) async {
    await _db.runTransaction((transaction) async {
      final walletRef = _db.collection('wallets').doc(userId);
      final walletDoc = await transaction.get(walletRef);
      double currentBalance = 0.0;
      if (walletDoc.exists) {
        currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      }

      if (walletDoc.exists) {
        transaction.update(walletRef, {'balance': currentBalance + amount});
      } else {
        transaction.set(walletRef, {'balance': currentBalance + amount});
      }

      transaction.set(_db.collection('transactions').doc(), {
        'paymentId': paymentId,
        'amount': amount,
        'commission': 0.0,
        'payoutAmount': amount,
        'jobId': '',
        'craftizenId': userId,
        'userId': userId,
        'category': 'wallet_recharge',
        'status': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> processJobPayment({
    required String jobId,
    required String craftizenId,
    required String userId,
    required double amount,
    required String category,
    required bool isCash,
    String? paymentId,
    required double commission,
  }) async {
    if (jobId.isEmpty || craftizenId.isEmpty) {
      throw Exception('INVALID_PAYMENT_DATA');
    }

    final payout = isCash ? 0.0 : (amount - commission);
    final debitAmount = isCash ? commission : 0.0;
    final creditAmount = isCash ? 0.0 : (amount - commission);

    try {
      await _db.runTransaction((transaction) async {
        final walletRef = _db.collection('wallets').doc(craftizenId);
        final walletDoc = await transaction.get(walletRef);
        double currentBalance = 0.0;
        if (walletDoc.exists) {
          currentBalance = (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        }

        if (isCash && currentBalance < commission) {
          throw Exception('INSUFFICIENT_BALANCE');
        }

        // Update wallet balance
        final newBalance = currentBalance + creditAmount - debitAmount;
        if (walletDoc.exists) {
          transaction.update(walletRef, {'balance': newBalance});
        } else {
          transaction.set(walletRef, {'balance': newBalance});
        }

        // Save transaction record
        final txRef = _db.collection('transactions').doc();
        transaction.set(txRef, {
          'paymentId': paymentId ?? 'CASH_${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'commission': commission,
          'payoutAmount': payout,
          'jobId': jobId,
          'craftizenId': craftizenId,
          'userId': userId,
          'category': category,
          'status': 'completed',
          'type': isCash ? 'cash_job' : 'online_job',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update job status
        final jobRef = _db.collection('jobs').doc(jobId);
        transaction.update(jobRef, {
          'jobStatus': 'paid',
          'paymentMethod': isCash ? 'cash' : 'online',
          'paymentStatus': 'paid',
          if (paymentId != null) 'paymentId': paymentId,
        });
      });
    } catch (e) {
      print('Payout Transaction Error: $e');
      rethrow;
    }
  }

  Future<void> requestWithdrawal(String userId, double amount, Map<String, String> bankDetails) async {
    final balance = await getWalletBalance(userId);
    if (amount > balance) throw Exception('Insufficient balance');

    await _db.runTransaction((transaction) async {
      final walletRef = _db.collection('wallets').doc(userId);
      transaction.update(walletRef, {'balance': balance - amount});

      transaction.set(_db.collection('withdrawals').doc(), {
        'userId': userId,
        'amount': amount,
        'bankDetails': bankDetails,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
