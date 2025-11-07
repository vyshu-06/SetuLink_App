import 'package:flutter/material.dart';

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
        title: const Text('Craftizen Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              "Welcome, ${widget.userObj['name'] ?? ''}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Skills: ${widget.userObj['skills']?.join(', ') ??
                  'Not specified'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Pending Jobs', '${pendingJobs
                    .where((job) => job['status'] == 'pending')
                    .length}', Icons.pending_actions),
                _buildStatCard('Accepted Jobs', '${pendingJobs
                    .where((job) => job['status'] == 'accepted')
                    .length}', Icons.assignment_turned_in),
                _buildStatCard('Earnings', '₹0', Icons.attach_money),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Current Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingJobs.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Jobs Available',
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
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        job['status'] == 'pending' ? Icons.pending : Icons
                            .assignment_turned_in,
                        color: job['status'] == 'pending'
                            ? Colors.orange
                            : Colors.green,
                      ),
                      title: Text(job['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['description'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            'Customer: ${job['userName']}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Chip(
                            label: Text(
                              job['status'] ?? 'pending',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: job['status'] == 'pending' ? Colors
                                .orange : Colors.green,
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap,
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to job details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Viewing job: ${job['title']}'),
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
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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