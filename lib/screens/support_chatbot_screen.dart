import 'package:flutter/material.dart';

class SupportChatbotScreen extends StatefulWidget {
  const SupportChatbotScreen({Key? key}) : super(key: key);

  @override
  State<SupportChatbotScreen> createState() => _SupportChatbotScreenState();
}

class _SupportChatbotScreenState extends State<SupportChatbotScreen> {
  final List<Map<String, String>> _messages = [
    {'sender': 'bot', 'text': 'Hello! How can I help you today?'}
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.insert(0, {'sender': 'user', 'text': text});
      _controller.clear();
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Call chatbot API - mock for now
    final reply = await getChatbotReply(text);

    setState(() {
      _messages.insert(0, {'sender': 'bot', 'text': reply});
    });
  }

  Future<String> getChatbotReply(String userMessage) async {
    // Integrate Dialogflow or other NLP service here.
    // For demo, simple keyword matching:
    final msg = userMessage.toLowerCase();
    if (msg.contains('payment') || msg.contains('refund')) {
      return 'For payment issues, please go to your Bookings page and raise a dispute on the specific job.';
    }
    if (msg.contains('quality') || msg.contains('work')) {
      return 'If you are unsatisfied with the work quality, you can raise a dispute directly from the job details page.';
    }
    if (msg.contains('human') || msg.contains('support') || msg.contains('agent')) {
      return 'I can connect you to a human agent. Please email support@setulink.com or use the "Raise Dispute" feature for job-specific issues.';
    }
    if (msg.contains('hello') || msg.contains('hi')) {
      return 'Hi there! Ask me about payments, job quality, or app features.';
    }
    return 'I am still learning. You can try asking about "payments" or "disputes". Alternatively, ask to speak to a human.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chatbot'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic),
            tooltip: 'Talk to Human',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent to support team. We will contact you shortly.')),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: !isUser ? Radius.zero : null,
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(fontSize: 16),
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
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.teal,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
