import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/craftizen_common_questions_screen.dart';

class CraftizenExperienceScreen extends StatefulWidget {
  final String userId;
  final List<String> selectedSkills;

  const CraftizenExperienceScreen({required this.userId, required this.selectedSkills, Key? key})
      : super(key: key);

  @override
  State<CraftizenExperienceScreen> createState() => _CraftizenExperienceScreenState();
}

class _CraftizenExperienceScreenState extends State<CraftizenExperienceScreen> {
  String? _experience;
  String? _radius;
  String? _isCertified;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'skills': widget.selectedSkills,
        'experienceLevel': _experience,
        'travelRadius': _radius,
        'isCertified': _isCertified == 'yes',
      });

      if (mounted) {
        // UPDATED: Navigate to the Common Questions screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CraftizenCommonQuestionsScreen(
              userId: widget.userId,
              selectedSkills: widget.selectedSkills,
            ), 
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: Text(tr('Tell us more'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildDropdown(
                    label: tr('How many years of experience do you have?'),
                    value: _experience,
                    items: ['0-1', '1-3', '3-5', '5+'],
                    onChanged: (val) => setState(() => _experience = val),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: tr('Mention your travel radius'),
                    value: _radius,
                    items: ['5 km', '10 km', '25 km', '50 km+'],
                    onChanged: (val) => setState(() => _radius = val),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: tr('Are you certified for your Skill?'),
                    value: _isCertified,
                    items: ['Yes', 'No'],
                    onChanged: (val) => setState(() => _isCertified = val),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveAndContinue,
                    child: Text(tr('Next')),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown({required String label, String? value, required List<String> items, ValueChanged<String?>? onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(tr(item)))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? tr('Please select an option') : null,
    );
  }
}
