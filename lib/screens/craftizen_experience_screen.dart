import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/skill_demo_upload_screen.dart'; // Import the correct next screen

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
        // UPDATED: Navigate to the Skill Demo Upload screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SkillDemoUploadScreen(userId: widget.userId), // Pass userId
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
      appBar: AppBar(title: Text(tr('tell_us_more'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  _buildDropdown(
                    label: tr('years_of_experience'),
                    value: _experience,
                    items: ['0-1', '1-3', '3-5', '5+'],
                    onChanged: (val) => setState(() => _experience = val),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: tr('travel_radius'),
                    value: _radius,
                    items: ['5 km', '10 km', '25 km', '50 km+'],
                    onChanged: (val) => setState(() => _radius = val),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(
                    label: tr('are_you_certified'),
                    value: _isCertified,
                    items: ['yes', 'no'],
                    onChanged: (val) => setState(() => _isCertified = val),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveAndContinue,
                    child: Text(tr('next')),
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
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(tr(item)))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? tr('please_select_an_option') : null,
    );
  }
}
