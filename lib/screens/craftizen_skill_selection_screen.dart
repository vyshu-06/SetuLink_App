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
  final List<Map<String, dynamic>> _allServiceCategories = [
    {
      'categoryKey': 'everyday_needs',
      'services': [
        {'title': 'plumber', 'key': 'plumber'},
        {'title': 'electrician', 'key': 'electrician'},
        {'title': 'carpenter', 'key': 'carpenter'},
        {'title': 'house_cleaner', 'key': 'house_cleaner'},
        {'title': 'gardener', 'key': 'gardener'},
        {'title': 'tailor', 'key': 'tailor'},
        {'title': 'painter', 'key': 'painter'},
        {'title': 'babysitter', 'key': 'babysitter'},
        {'title': 'laundry', 'key': 'laundry'},
        {'title': 'elderly_caregiver', 'key': 'elderly_caregiver'},
        {'title': 'pet_care', 'key': 'pet_care'},
        {'title': 'driver', 'key': 'driver'},
      ],
    },
    {
      'categoryKey': 'semi_technical',
      'services': [
        {'title': 'mobile_repair', 'key': 'mobile_repair'},
        {'title': 'appliance_repair', 'key': 'appliance_repair'},
        {'title': 'tv_setup', 'key': 'tv_setup'},
        {'title': 'cctv', 'key': 'cctv'},
        {'title': 'wifi', 'key': 'wifi'},
        {'title': 'home_automation', 'key': 'home_automation'},
        {'title': 'solar_installers', 'key': 'solar_installers'},
      ],
    },
    {
      'categoryKey': 'community_skills',
      'services': [
        {'title': 'tutor', 'key': 'tutor'},
        {'title': 'yoga_trainer', 'key': 'yoga_trainer'},
        {'title': 'music_teacher', 'key': 'music_teacher'},
        {'title': 'event_assistant', 'key': 'event_assistant'},
        {'title': 'errand_helper', 'key': 'errand_helper'},
      ],
    },
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
      appBar: AppBar(title: Text(tr('select_the_skills_you_have_experience_in'))),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _allServiceCategories.length,
              itemBuilder: (context, index) {
                final category = _allServiceCategories[index];
                final services = category['services'] as List<Map<String, String>>;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        tr(category['categoryKey']),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...services.map((service) {
                       return CheckboxListTile(
                        title: Text(tr(service['title']!)),
                        value: _selectedSkills.contains(service['key']!),
                        onChanged: (selected) => _onSkillSelected(selected, service['key']!),
                      );
                    }).toList(),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _continueToNextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(tr('next')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
