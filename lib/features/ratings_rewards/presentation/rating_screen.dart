import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
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
  double _qualityRating = 5.0;
  String? _behaviour;
  bool _extraChargesDemanded = false;
  bool _recommendToOthers = true;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _behaviourOptions = [
    'professional',
    'friendly',
    'punctual',
    'rude',
  ];

  Future<void> _submitRating() async {
    if (_behaviour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('please_select_option'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Save the detailed review
      await FirebaseFirestore.instance.collection('reviews').add({
        'jobId': widget.jobId,
        'craftizenId': widget.craftizenId,
        'qualityRating': _qualityRating,
        'behaviour': _behaviour,
        'extraChargesDemanded': _extraChargesDemanded,
        'recommendToOthers': _recommendToOthers,
        'comment': _commentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update the Craftizen's overall rating (using quality as primary)
      final craftizenDoc = await FirebaseFirestore.instance.collection('users').doc(widget.craftizenId).get();
      if (craftizenDoc.exists) {
        final data = craftizenDoc.data()!;
        double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        int ratingCount = (data['ratingCount'] as int?) ?? 0;

        double newRating = ((currentRating * ratingCount) + _qualityRating) / (ratingCount + 1);
        
        await FirebaseFirestore.instance.collection('users').doc(widget.craftizenId).update({
          'rating': newRating,
          'ratingCount': ratingCount + 1,
        });
      }

      // 3. Mark job as rated
      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
        'rated': true,
        'jobStatus': 'closed',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: BilingualText(textKey: 'feedback_submitted')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/citizen_home', (route) => false);
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
      appBar: AppBar(
        title: const BilingualText(textKey: 'rate_experience'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('quality_of_work'),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _qualityRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 45,
                    ),
                    onPressed: () => setState(() => _qualityRating = index + 1.0),
                  );
                }),
              ),
            ),
            const Divider(height: 40),

            _buildSectionHeader('behaviour'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _behaviourOptions.map((opt) => ChoiceChip(
                label: BilingualText(textKey: opt),
                selected: _behaviour == opt,
                onSelected: (selected) {
                  setState(() => _behaviour = selected ? opt : null);
                },
                selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryColor,
              )).toList(),
            ),
            const Divider(height: 40),

            _buildYesNoQuestion('extra_charges_demanded', _extraChargesDemanded, (val) {
              setState(() => _extraChargesDemanded = val);
            }),
            const Divider(height: 40),

            _buildYesNoQuestion('recommend_to_others', _recommendToOthers, (val) {
              setState(() => _recommendToOthers = val);
            }),
            const Divider(height: 40),

            _buildSectionHeader('description'), // Comments
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: tr('describe_what_needs_to_be_done'), // Placeholder for "Tell us more"
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const BilingualText(textKey: 'submit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String textKey) {
    return BilingualText(
      textKey: textKey,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
    );
  }

  Widget _buildYesNoQuestion(String textKey, bool value, Function(bool) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(textKey),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(true),
                style: OutlinedButton.styleFrom(
                  backgroundColor: value ? Colors.green.withValues(alpha: 0.1) : null,
                  side: BorderSide(color: value ? Colors.green : Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const BilingualText(textKey: 'yes'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onChanged(false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: !value ? Colors.red.withValues(alpha: 0.1) : null,
                  side: BorderSide(color: !value ? Colors.red : Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const BilingualText(textKey: 'no'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
