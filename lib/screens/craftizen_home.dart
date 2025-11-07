import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CraftizenHome extends StatefulWidget {
  final Map<String, dynamic> userObj;
  const CraftizenHome({required this.userObj, Key? key}) : super(key: key);

  @override
  State<CraftizenHome> createState() => _CraftizenHomeState();
}

class _CraftizenHomeState extends State<CraftizenHome> {
  List<Map<String, dynamic>> pendingJobs = [];

  @override
  void initState() {
    super.initState();
    _loadPendingJobs();
  }

  Future<void> _loadPendingJobs() async {
    // This is a placeholder - replace with actual Firestore query
    // Example: Query jobs where craftizenId matches and status is pending
    setState(() {
      pendingJobs = [
        {
          'id': '1',
          'title': 'Plumbing Repair',
          'description': 'Fix leaking pipe in kitchen',
          'status': 'pending',
          'userName': 'John Doe',
        },
        {
          'id': '2',
          'title': 'Electrical Work',
          'description': 'Install new light fixtures',
          'status': 'accepted',
          'userName': 'Jane Smith',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('craftizen_dashboard'.tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Add logout functionality here
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${'welcome'.tr()}, ${widget.userObj['name'] ?? ''}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'your_skills'.tr() + ': ${widget.userObj['skills']?.join(', ') ?? 'Not specified'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('pending_jobs'.tr(), '${pendingJobs.where((job) => job['status'] == 'pending').length}', Icons.pending_actions),
                _buildStatCard('accepted_jobs'.tr(), '${pendingJobs.where((job) => job['status'] == 'accepted').length}', Icons.assignment_turned_in),
                _buildStatCard('earnings'.tr(), '₹0', Icons.attach_money),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'current_jobs'.tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: pendingJobs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'no_jobs_available'.tr(),
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: pendingJobs.length,
                itemBuilder: (context, index) {
                  final job = pendingJobs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        job['status'] == 'pending' ? Icons.pending : Icons.assignment_turned_in,
                        color: job['status'] == 'pending' ? Colors.orange : Colors.green,
                      ),
                      title: Text(job['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['description'] ?? ''),
                          SizedBox(height: 4),
                          Text(
                            '${'customer'.tr()}: ${job['userName']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Chip(
                            label: Text(
                              job['status'] ?? 'pending',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: job['status'] == 'pending' ? Colors.orange : Colors.green,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to job details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${'viewing_job'.tr()}: ${job['title']}'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.teal),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}