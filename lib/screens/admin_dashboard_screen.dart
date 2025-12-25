import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/admin_user_management_screen.dart';
import 'package:setulink_app/screens/admin_dispute_management_screen.dart';
import 'package:setulink_app/screens/admin_analytics_screen.dart';
import 'package:setulink_app/screens/admin_jobs_list_screen.dart';
import 'package:setulink_app/screens/admin_payments_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('admin_dashboard'))),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildDashboardCard(
            context,
            title: tr('user_management'),
            icon: Icons.people,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: tr('job_monitor'),
            icon: Icons.work,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminJobsListScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: tr('dispute_resolution'),
            icon: Icons.gavel,
             onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DisputeManagementScreen()));
            },
          ),
          _buildDashboardCard(
            context,
            title: tr('finance_and_payouts'), 
            icon: Icons.monetization_on, 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsScreen()));
            }
          ),
          _buildDashboardCard(
            context,
            title: tr('analytics'), 
            icon: Icons.analytics, 
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
