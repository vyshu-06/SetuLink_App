import 'package:flutter/material.dart';
import 'package:setulink_app/screens/subscription_screen.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  SubscriptionPlansScreen({super.key});

  final List<Map<String, dynamic>> plans = [
    {'name': 'Basic', 'price': 0, 'commission': 15, 'plan_id': 'YOUR_BASIC_PLAN_ID'},
    {'name': 'Standard', 'price': 1000, 'commission': 10, 'plan_id': 'YOUR_STANDARD_PLAN_ID'},
    {'name': 'Premium', 'price': 2500, 'commission': 7, 'plan_id': 'YOUR_PREMIUM_PLAN_ID'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return ListTile(
            title: Text('${plan['name']} - ₹${plan['price']}'),
            subtitle: Text('Commission: ${plan['commission']}% '),
            trailing: ElevatedButton(
              onPressed: () {
                if (plan['price'] > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(planId: plan['plan_id']),
                    ),
                  );
                } else {
                  // Handle free plan selection
                }
              },
              child: Text(plan['price'] == 0 ? 'Free' : 'Subscribe'),
            ),
          );
        },
      ),
    );
  }
}
