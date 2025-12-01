import 'package:flutter/material.dart';
import 'package:setulink_app/models/dispute_model.dart';
import 'package:setulink_app/services/dispute_service.dart';
import 'package:intl/intl.dart';
import 'package:setulink_app/screens/dispute_chat_screen.dart';

class DisputeManagementScreen extends StatefulWidget {
  const DisputeManagementScreen({Key? key}) : super(key: key);

  @override
  _DisputeManagementScreenState createState() => _DisputeManagementScreenState();
}

class _DisputeManagementScreenState extends State<DisputeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DisputeService _disputeService = DisputeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Resolution'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Disputes'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DisputeList(service: _disputeService, status: 'open'),
          _DisputeList(service: _disputeService, status: 'resolved'),
        ],
      ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  final DisputeService service;
  final String status;

  const _DisputeList({Key? key, required this.service, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DisputeModel>>(
      stream: service.getAllDisputes(status: status),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final disputes = snapshot.data!;
        if (disputes.isEmpty) return const Center(child: Text('No disputes found'));

        return ListView.builder(
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final dispute = disputes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Dispute #${dispute.id.substring(0, 6)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${dispute.type}'),
                    Text('Raised by: ${dispute.raisedBy}'),
                    Text('Date: ${DateFormat('dd MMM yyyy').format(dispute.createdAt.toDate())}'),
                    if (dispute.escalationRequested)
                      const Text('ESCALATED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: status == 'open'
                    ? ElevatedButton(
                        onPressed: () => _showResolveDialog(context, dispute),
                        child: const Text('Resolve'),
                      )
                    : const Icon(Icons.check_circle, color: Colors.green),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DisputeChatScreen(
                        disputeId: dispute.id,
                        currentUserId: 'admin', // Admin ID or flag
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showResolveDialog(BuildContext context, DisputeModel dispute) {
    final noteController = TextEditingController();
    String outcome = 'refund_full';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: outcome,
              items: const [
                DropdownMenuItem(value: 'refund_full', child: Text('Full Refund')),
                DropdownMenuItem(value: 'refund_partial', child: Text('Partial Refund')),
                DropdownMenuItem(value: 'no_refund', child: Text('No Refund / Rejected')),
                DropdownMenuItem(value: 'warning_issued', child: Text('Issue Warning')),
              ],
              onChanged: (val) => outcome = val!,
              decoration: const InputDecoration(labelText: 'Outcome'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Resolution Note'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              service.resolveDispute(dispute.id, outcome, noteController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dispute Resolved')),
              );
            },
            child: const Text('Submit Resolution'),
          ),
        ],
      ),
    );
  }
}
