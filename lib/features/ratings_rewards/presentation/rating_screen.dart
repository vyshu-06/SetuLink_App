import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class RatingScreen extends StatefulWidget {
  final String jobId;
  final String craftizenId;

  const RatingScreen({Key? key, required this.jobId, required this.craftizenId}) : super(key: key);

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      // 1. Save the review to a global 'reviews' collection
      await FirebaseFirestore.instance.collection('reviews').add({
        'jobId': widget.jobId,
        'craftizenId': widget.craftizenId,
        'rating': _rating,
        'comment': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update the Craftizen's overall rating
      final craftizenDoc = await FirebaseFirestore.instance.collection('users').doc(widget.craftizenId).get();
      if (craftizenDoc.exists) {
        final data = craftizenDoc.data()!;
        double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        int ratingCount = (data['ratingCount'] as int?) ?? 0;

        double newRating = ((currentRating * ratingCount) + _rating) / (ratingCount + 1);
        
        await FirebaseFirestore.instance.collection('users').doc(widget.craftizenId).update({
          'rating': newRating,
          'ratingCount': ratingCount + 1,
        });
      }

      // 3. Mark job as rated
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'rated': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const BilingualText(textKey: 'complete')), // Placeholder
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const BilingualText(textKey: 'tagline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: BilingualText(textKey: 'description'),
              ),
              maxLines: 3,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSubmitting ? const CircularProgressIndicator() : const BilingualText(textKey: 'complete'),
            ),
          ],
        ),
      ),
    );
  }
}
