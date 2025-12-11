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
      // Replaced 'value' with 'value' because initialValue doesn't support updates via setState.
      // Wait, standard practice for controlled inputs IS 'value'. The warning suggests using initialValue for form fields but if I want to update it programmatically or reset, I need 'value'.
      // If I use initialValue, the widget manages its own state and setState won't update the displayed value if 'value' changes.
      // However, if the user only changes it via interaction, initialValue is fine if I don't reset it.
      // But here I am passing `value: _experience` which is state.
      // If I change to `initialValue: value`, then selecting an item updates the internal state of the dropdown, and `onChanged` updates my `_experience`. 
      // If `_experience` changes from outside (not happening here), `initialValue` wouldn't reflect it.
      // Since this is a simple form where selection only happens via user input, `initialValue` works fine and clears the warning.
      // BUT, `value` is `_experience` which starts as null.
      // Let's use `value` as it's the most correct for controlled component, but if I MUST fix the warning, I'll switch to `initialValue` and ensure `key` is used if reset is needed (it's not needed here).
      // Actually, looking at the warning again: "Use initialValue instead. This will set the initial value for the form field."
      // If I use `value`, the form field is forced to that value. If I use `initialValue`, it just starts there.
      // Since I am updating state in `onChanged`, using `value` makes it controlled.
      // To properly "fix" the warning while keeping functionality, I should probably check if I can just ignore it or if I really don't need controlled behavior.
      // Here, `_experience` is only updated by the dropdown itself. So `initialValue` is actually sufficient if we don't reset the form programmatically without rebuilding.
      // However, usually `DropdownButtonFormField` requires `value` to show the current selection if you want to be able to change it programmatically or if it depends on other state.
      // I will keep `value` but ignore the warning if I can't easily suppress.
      // Wait, I can try `initialValue` with `key` approach or just `value`.
      // The user ASKED to implement hints. So I will change to `initialValue`.
      initialValue: value,
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
