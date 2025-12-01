import 'package:flutter/material.dart';
import 'package:setulink_app/models/dispute_model.dart';
import 'package:setulink_app/services/dispute_service.dart';
import 'package:intl/intl.dart';

class DisputeChatScreen extends StatefulWidget {
  final String disputeId;
  final String currentUserId;

  const DisputeChatScreen({
    Key? key,
    required this.disputeId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _DisputeChatScreenState createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DisputeService _disputeService = DisputeService();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    _disputeService.sendMessage(
      widget.disputeId,
      widget.currentUserId,
      _messageController.text.trim(),
    );
    _messageController.clear();
  }

  void _requestEscalation() {
    _disputeService.requestEscalation(widget.disputeId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Escalation requested. Support team will review this shortly.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            tooltip: 'Request Escalation',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Escalate Dispute?'),
                  content: const Text(
                      'If you cannot resolve this with the other party, our support team can intervene.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _requestEscalation();
                      },
                      child: const Text('Escalate'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DisputeModel>(
        stream: _disputeService.getDispute(widget.disputeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final dispute = snapshot.data!;
          final messages = dispute.messages.reversed.toList(); // Show newest at bottom usually, but Listview reverse=true needs newest at index 0

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${dispute.status.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Type: ${dispute.type}'),
                          if (dispute.escalationRequested)
                            const Text('Escalation Requested',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true, // Bottom to top
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index]; // reversed list, so index 0 is latest? 
                    // Wait, if I reversed the list from Firestore (which has old->new), then reversed list has new->old.
                    // ListView reverse=true starts from bottom. It expects index 0 to be bottom-most (latest).
                    // So passing reversed list is correct if list was chronological.
                    
                    // Actually, Firestore array order is chronological. 
                    // So messages.last is latest.
                    // `reversed.toList()` makes latest at index 0.
                    // ListView reverse=true puts index 0 at bottom. Correct.

                    final isMe = msg.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.message),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(msg.timestamp.toDate()),
                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
