import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Placeholder for total earnings and withdrawal options
            Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor),
                title: const Text('Total Earned'),
                subtitle: const Text('Coming Soon'),
                trailing: const Text('₹0.00', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: null, // Disabled for now
              child: const Text('Withdraw Funds'),
            ),
            const SizedBox(height: 40),
            const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Expanded(
              child: Center(
                child: Text('No transactions yet.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
