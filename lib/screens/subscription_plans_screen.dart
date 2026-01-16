import 'package:flutter/material.dart';
import 'package:setulink_app/screens/subscription_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/theme/app_colors.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  SubscriptionPlansScreen({super.key});

  final List<Map<String, dynamic>> plans = [
    {'name': 'basic', 'price': 0, 'commission': 15, 'plan_id': 'YOUR_BASIC_PLAN_ID'},
    {'name': 'standard', 'price': 1000, 'commission': 10, 'plan_id': 'YOUR_STANDARD_PLAN_ID'},
    {'name': 'premium', 'price': 2500, 'commission': 7, 'plan_id': 'YOUR_PREMIUM_PLAN_ID'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'subscription_plans'),
      ),
      body: ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  BilingualText(textKey: plan['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('₹${plan['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${tr('platform_commission')}: ${plan['commission']}%'),
              ),
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
                child: BilingualText(textKey: plan['price'] == 0 ? 'yes' : 'subscribe_now'), // 'yes' as placeholder for free
              ),
            ),
          );
        },
      ),
    );
  }
}
