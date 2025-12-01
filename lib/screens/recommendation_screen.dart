import 'package:flutter/material.dart';
import 'package:setulink_app/models/craftizen_model.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  final JobModel job;
  const RecommendationScreen({Key? key, required this.job}) : super(key: key);

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late Future<List<CraftizenModel>> _recommendationsFuture;
  final RecommendationService _recommendationService = RecommendationService();

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _recommendationService.getTopMatches(widget.job);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Craftizens')),
      body: FutureBuilder<List<CraftizenModel>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No matches found. Try broadening your criteria.'));
          }

          final craftizens = snapshot.data!;

          return ListView.builder(
            itemCount: craftizens.length,
            itemBuilder: (context, index) {
              final craftizen = craftizens[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(craftizen.name[0]),
                  ),
                  title: Text(craftizen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.star, color: Colors.amber, size: 16), Text(' ${craftizen.rating.toStringAsFixed(1)}')]),
                      Text('Skills: ${craftizen.skills.join(', ')}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Invite logic
                      // e.g., update job doc with invitedCraftizenId
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invited ${craftizen.name}')),
                      );
                    },
                    child: const Text('Invite'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
