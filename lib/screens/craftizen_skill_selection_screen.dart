import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/craftizen_experience_screen.dart';

class CraftizenSkillSelectionScreen extends StatefulWidget {
  final String userId;

  const CraftizenSkillSelectionScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<CraftizenSkillSelectionScreen> createState() => _CraftizenSkillSelectionScreenState();
}

class _CraftizenSkillSelectionScreenState extends State<CraftizenSkillSelectionScreen> {
  final List<Map<String, String>> _availableSkills = const [
    {'title': 'Plumber', 'key': 'plumber'},
    {'title': 'Electrician', 'key': 'electrician'},
    {'title': 'Carpenter', 'key': 'carpenter'},
    {'title': 'Painter', 'key': 'painter'},
    {'title': 'Mechanic', 'key': 'mechanic'},
    {'title': 'Appliance Repair', 'key': 'appliance_repair'},
  ];

  final Set<String> _selectedSkills = {};

  void _onSkillSelected(bool? selected, String skillKey) {
    setState(() {
      if (selected == true) {
        _selectedSkills.add(skillKey);
      } else {
        _selectedSkills.remove(skillKey);
      }
    });
  }

  void _continueToNextStep() {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('please_select_at_least_one_skill'))),
      );
      return;
    }

    // FIX: Navigate to the experience screen, passing the selected skills.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CraftizenExperienceScreen(
          userId: widget.userId,
          selectedSkills: _selectedSkills.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('select_your_skills'))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _availableSkills.length,
              itemBuilder: (context, index) {
                final skill = _availableSkills[index];
                return CheckboxListTile(
                  title: Text(tr(skill['title']!)),
                  value: _selectedSkills.contains(skill['key']!),
                  onChanged: (selected) => _onSkillSelected(selected, skill['key']!),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _continueToNextStep,
              child: Text(tr('next')),
            ),
          ),
        ],
      ),
    );
  }
}
