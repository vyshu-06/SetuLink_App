import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/services/payout_service.dart';
import 'package:setulink_app/services/payment_service.dart';
import 'package:setulink_app/models/transaction_model.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final PayoutService _payoutService = PayoutService();
  final PaymentService _paymentService = PaymentService();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentViewIndex = 0; // 0 for Earnings, 1 for Transactions

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const Scaffold(body: Center(child: BilingualText(textKey: 'log_in_to_see_bookings')));

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'my_earnings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildWalletHeader(),
          const SizedBox(height: 16),
          _buildViewToggle(),
          Expanded(
            child: _currentViewIndex == 0 ? _buildEarningsView() : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentViewIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentViewIndex == 0 ? AppColors.primaryColor : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                ),
                child: Center(
                  child: BilingualText(
                    textKey: 'my_earnings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentViewIndex == 0 ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentViewIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _currentViewIndex == 1 ? AppColors.primaryColor : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                ),
                child: Center(
                  child: BilingualText(
                    textKey: 'transaction_history',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _currentViewIndex == 1 ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _payoutService.getTransactions(userId, isCraftizen: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        double dailyTotal = 0;
        double weeklyTotal = 0;
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: now.weekday - 1));

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final type = data['type'] ?? '';
          final category = data['category'] ?? '';
          
          if (category == 'wallet_recharge') continue;

          double amount = 0;
          if (type == 'cash_job') {
            // For cash jobs, the craftizen "earned" the whole budget, 
            // even though commission was debited from wallet.
            amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          } else {
            // For online jobs, they earned the payout amount
            amount = (data['payoutAmount'] as num?)?.toDouble() ?? 0.0;
          }

          if (timestamp.isAfter(today)) {
            dailyTotal += amount;
          }
          if (timestamp.isAfter(weekStart)) {
            weeklyTotal += amount;
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildEarningCard('daily_earnings', dailyTotal, Icons.today, Colors.blue),
            const SizedBox(height: 16),
            _buildEarningCard('weekly_earnings', weeklyTotal, Icons.date_range, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildEarningCard(String titleKey, double amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BilingualText(textKey: titleKey, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _payoutService.getWalletStream(userId),
      builder: (context, snapshot) {
        double balance = 0.0;
        if (snapshot.hasData && snapshot.data!.exists) {
          balance = (snapshot.data!['balance'] as num?)?.toDouble() ?? 0.0;
        }

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              const BilingualText(textKey: 'Amount', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRechargeDialog(),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const BilingualText(textKey: 'recharge_wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: balance > 0 ? () => _showWithdrawDialog(balance) : null,
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const BilingualText(textKey: 'withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                ],
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
        if (docs.isEmpty) return const Center(child: BilingualText(textKey: 'no_jobs_available'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final category = data['category'] ?? '';
            final type = data['type'] ?? '';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final commission = (data['commission'] as num?)?.toDouble() ?? 0.0;
            final payout = (data['payoutAmount'] as num?)?.toDouble() ?? 0.0;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

            bool isDebit = type == 'cash_job';
            bool isRecharge = category == 'wallet_recharge';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRecharge ? Colors.green.withValues(alpha: 0.1) : (isDebit ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
                  child: Icon(
                    isRecharge ? Icons.add_card : (isDebit ? Icons.money_off : Icons.work),
                    color: isRecharge ? Colors.green : (isDebit ? Colors.orange : Colors.blue),
                  ),
                ),
                title: Text(isRecharge ? 'Wallet Recharge' : (isDebit ? 'Commission for Cash Job' : category.toUpperCase())),
                subtitle: Text(DateFormat('dd MMM, hh:mm a').format(timestamp)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isRecharge ? '+₹${amount.toStringAsFixed(0)}' : (isDebit ? '-₹${commission.toStringAsFixed(0)}' : '+₹${payout.toStringAsFixed(0)}'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isRecharge || (!isDebit) ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!isRecharge)
                      Text('Total: ₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRechargeDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const BilingualText(textKey: 'recharge_wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to add to your wallet:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                hintText: 'e.g. 500',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const BilingualText(textKey: 'back')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                Navigator.pop(context);
                _processRecharge(amount);
              }
            },
            child: const BilingualText(textKey: 'next'),
          ),
        ],
      ),
    );
  }

  void _processRecharge(double amount) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _paymentService.openCheckout(
      amount: amount,
      userName: currentUser.displayName ?? 'Craftizen',
      userEmail: currentUser.email ?? '',
      category: 'wallet_recharge',
      onSuccess: (paymentId) async {
        await _payoutService.rechargeWallet(userId, amount, paymentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallet recharged successfully!')));
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recharge failed: $error')));
        }
      },
    );
  }

  void _showWithdrawDialog(double balance) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const BilingualText(textKey: 'withdraw'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested successfully!')));
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
