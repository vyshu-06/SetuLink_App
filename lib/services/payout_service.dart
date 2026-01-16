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
