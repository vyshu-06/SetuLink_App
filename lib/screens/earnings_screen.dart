import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('my_earnings'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Placeholder for total earnings and withdrawal options
            Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
                title: Text(tr('total_earned')),
                subtitle: Text(tr('coming_soon')),
                trailing: const Text('₹0.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: null, // Disabled for now
              child: Text(tr('withdraw_funds')),
            ),
            const SizedBox(height: 40),
            Text(tr('transaction_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(
              child: Center(
                child: Text(tr('no_transactions_yet')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
