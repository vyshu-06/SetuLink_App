import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/services/payout_service.dart';
import 'package:setulink_app/models/transaction_model.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:intl/intl.dart';
import 'package:setulink_app/theme/app_colors.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final PayoutService _payoutService = PayoutService();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const Center(child: BilingualText(textKey: 'log_in_to_see_bookings'));

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'jobs_page_title'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          _buildBalanceHeader(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: BilingualText(textKey: 'jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(child: _buildTransactionList()),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return FutureBuilder<double>(
      future: _payoutService.getWalletBalance(userId),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const BilingualText(textKey: 'amount', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: balance > 0 ? () => _showWithdrawDialog(balance) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryColor),
                child: const BilingualText(textKey: 'complete'), // Placeholder for Withdraw
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _payoutService.getTransactions(userId, isCraftizen: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: BilingualText(textKey: 'no_accepted_jobs_yet'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final tx = TransactionModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.work)),
              title: Text(tx.category.toUpperCase()),
              subtitle: Text(DateFormat('dd MMM yyyy').format(tx.timestamp)),
              trailing: Text('+₹${tx.payoutAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }

  void _showWithdrawDialog(double balance) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const BilingualText(textKey: 'complete'), // Withdraw
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const BilingualText(textKey: 'back')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && amount <= balance) {
                await _payoutService.requestWithdrawal(userId, amount, {'method': 'bank_transfer'});
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh balance
                }
              }
            },
            child: const BilingualText(textKey: 'complete'),
          ),
        ],
      ),
    );
  }
}
