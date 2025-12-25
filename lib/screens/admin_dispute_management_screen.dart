import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
        title: Text(tr('dispute_resolution')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: tr('active_disputes')),
            Tab(text: tr('resolved')),
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
        if (snapshot.hasError) return Center(child: Text('${tr('error')}: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final disputes = snapshot.data!;
        if (disputes.isEmpty) return Center(child: Text(tr('no_disputes_found')));

        return ListView.builder(
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final dispute = disputes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('${tr('dispute')} #${dispute.id.substring(0, 6)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${tr('type')}: ${dispute.type}'),
                    Text('${tr('raised_by')}: ${dispute.raisedBy}'),
                    Text('${tr('date')}: ${DateFormat('dd MMM yyyy').format(dispute.createdAt.toDate())}'),
                    if (dispute.escalationRequested)
                      Text(tr('escalated').toUpperCase(), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: status == 'open'
                    ? ElevatedButton(
                        onPressed: () => _showResolveDialog(context, dispute),
                        child: Text(tr('resolve')),
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(tr('resolve_dispute')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InputDecorator(
                  decoration: InputDecoration(labelText: tr('outcome'), border: const OutlineInputBorder()),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: outcome,
                      isDense: true,
                      items: [
                        DropdownMenuItem(value: 'refund_full', child: Text(tr('full_refund'))),
                        DropdownMenuItem(value: 'refund_partial', child: Text(tr('partial_refund'))),
                        DropdownMenuItem(value: 'no_refund', child: Text(tr('no_refund_rejected'))),
                        DropdownMenuItem(value: 'warning_issued', child: Text(tr('issue_warning'))),
                      ],
                      onChanged: (val) {
                        setState(() {
                           outcome = val!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: tr('resolution_note')),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
              ElevatedButton(
                onPressed: () {
                  service.resolveDispute(dispute.id, outcome, noteController.text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('dispute_resolved'))),
                  );
                },
                child: Text(tr('submit_resolution')),
              ),
            ],
          );
        },
      ),
    );
  }
}
