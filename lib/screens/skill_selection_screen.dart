import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/craftizen_common_questions_screen.dart';

class SkillSelectionScreen extends StatefulWidget {
  final String userId;

  const SkillSelectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SkillSelectionScreen> createState() => _SkillSelectionScreenState();
}

class _SkillSelectionScreenState extends State<SkillSelectionScreen> {
  final List<String> _selectedSkills = [];

  final List<Map<String, dynamic>> _allServiceCategories = [
    {
      'categoryKey': 'everyday_needs',
      'services': [
        {'titleKey': 'plumber', 'icon': Icons.plumbing},
        {'titleKey': 'electrician', 'icon': Icons.electrical_services},
        {'titleKey': 'carpenter', 'icon': Icons.handyman},
        {'titleKey': 'house_cleaner', 'icon': Icons.cleaning_services},
        {'titleKey': 'gardener', 'icon': Icons.local_florist},
        {'titleKey': 'tailor', 'icon': Icons.cut},
        {'titleKey': 'painter', 'icon': Icons.format_paint},
        {'titleKey': 'babysitter', 'icon': Icons.child_friendly},
        {'titleKey': 'laundry', 'icon': Icons.local_laundry_service},
        {'titleKey': 'elderly_caregiver', 'icon': Icons.elderly},
        {'titleKey': 'pet_care', 'icon': Icons.pets},
        {'titleKey': 'driver', 'icon': Icons.drive_eta},
      ],
    },
    {
      'categoryKey': 'semi_technical',
      'services': [
        {'titleKey': 'mobile_repair', 'icon': Icons.phonelink_setup},
        {'titleKey': 'appliance_repair', 'icon': Icons.build_circle},
        {'titleKey': 'tv_setup', 'icon': Icons.tv},
        {'titleKey': 'cctv', 'icon': Icons.videocam},
        {'titleKey': 'wifi', 'icon': Icons.wifi},
        {'titleKey': 'home_automation', 'icon': Icons.settings_remote},
        {'titleKey': 'solar_installers', 'icon': Icons.solar_power},
      ],
    },
    {
      'categoryKey': 'community_skills',
      'services': [
        {'titleKey': 'tutor', 'icon': Icons.school},
        {'titleKey': 'yoga_trainer', 'icon': Icons.self_improvement},
        {'titleKey': 'music_teacher', 'icon': Icons.music_note},
        {'titleKey': 'event_assistant', 'icon': Icons.event},
        {'titleKey': 'errand_helper', 'icon': Icons.run_circle},
      ],
    },
  ];

  void _onSkillSelected(bool? selected, String skill) {
    setState(() {
      if (selected == true) {
        _selectedSkills.add(skill);
      } else {
        _selectedSkills.remove(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('select_your_skills')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ..._allServiceCategories.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                  child: Text(
                    tr(category['categoryKey']!),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ...(
                  category['services'] as List<Map<String, dynamic>>).map((service) {
                    final skill = tr(service['titleKey']!);
                    return CheckboxListTile(
                      title: Text(skill),
                      value: _selectedSkills.contains(skill),
                      onChanged: (selected) => _onSkillSelected(selected, skill),
                    );
                  }).toList(),
              ],
            );
          }).toList(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CraftizenCommonQuestionsScreen(
                    userId: widget.userId,
                    selectedSkills: _selectedSkills,
                  ),
                ),
              );
            },
            child: Text(tr('next')),
          ),
        ],
      ),
    );
  }
}
