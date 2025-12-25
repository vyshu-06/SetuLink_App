import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('platform_analytics'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('overview'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _MetricCard(collection: 'users', label: tr('total_users'), icon: Icons.people)),
                const SizedBox(width: 16),
                Expanded(child: _MetricCard(collection: 'jobs', label: tr('total_jobs'), icon: Icons.work)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _MetricCard(collection: 'disputes', label: tr('disputes'), icon: Icons.gavel, color: Colors.red)),
                const SizedBox(width: 16),
                // Placeholder for GMV or other calculated metrics
                Expanded(child: _StaticMetricCard(label: tr('active_cities'), value: '12', icon: Icons.location_city, color: Colors.purple)),
              ],
            ),
            const SizedBox(height: 32),
            Text(tr('recent_growth'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(child: Text(tr('charts_coming_soon'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String collection;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricCard({
    Key? key,
    required this.collection,
    required this.label,
    required this.icon,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AggregateQuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).count().get().asStream(),
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          value = snapshot.data!.count.toString();
        }
        return _StaticMetricCard(label: label, value: value, icon: icon, color: color);
      },
    );
  }
}

class _StaticMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StaticMetricCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
