import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String paymentId;
  final double amount;
  final double commission;
  final double payoutAmount;
  final String jobId;
  final String craftizenId;
  final String userId;
  final String category;
  final String status;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.commission,
    required this.payoutAmount,
    required this.jobId,
    required this.craftizenId,
    required this.userId,
    required this.category,
    required this.status,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> data, String id) {
    return TransactionModel(
      id: id,
      paymentId: data['paymentId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      commission: (data['commission'] as num?)?.toDouble() ?? 0.0,
      payoutAmount: (data['payoutAmount'] as num?)?.toDouble() ?? 0.0,
      jobId: data['jobId'] ?? '',
      craftizenId: data['craftizenId'] ?? '',
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
