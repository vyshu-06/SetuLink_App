import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/craftizen_experience_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class CraftizenSkillSelectionScreen extends StatefulWidget {
  final String userId;

  const CraftizenSkillSelectionScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<CraftizenSkillSelectionScreen> createState() => _CraftizenSkillSelectionScreenState();
}

class _CraftizenSkillSelectionScreenState extends State<CraftizenSkillSelectionScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _allServiceCategories = [
    {
      'categoryKey': 'everyday_needs',
      'services': [
        {'title': 'plumber', 'key': 'plumber', 'icon': Icons.plumbing},
        {'title': 'electrician', 'key': 'electrician', 'icon': Icons.electrical_services},
        {'title': 'carpenter', 'key': 'carpenter', 'icon': Icons.handyman},
        {'title': 'house_cleaner', 'key': 'house_cleaner', 'icon': Icons.cleaning_services},
        {'title': 'gardener', 'key': 'gardener', 'icon': Icons.local_florist},
        {'title': 'tailor', 'key': 'tailor', 'icon': Icons.cut},
        {'title': 'painter', 'key': 'painter', 'icon': Icons.format_paint},
        {'title': 'babysitter', 'key': 'babysitter', 'icon': Icons.child_friendly},
        {'title': 'laundry', 'key': 'laundry', 'icon': Icons.local_laundry_service},
        {'title': 'elderly_caregiver', 'key': 'elderly_caregiver', 'icon': Icons.elderly},
        {'title': 'pet_care', 'key': 'pet_care', 'icon': Icons.pets},
        {'title': 'driver', 'key': 'driver', 'icon': Icons.drive_eta},
      ],
    },
    {
      'categoryKey': 'semi_technical',
      'services': [
        {'title': 'mobile_repair', 'key': 'mobile_repair', 'icon': Icons.phonelink_setup},
        {'title': 'appliance_repair', 'key': 'appliance_repair', 'icon': Icons.build_circle},
        {'title': 'tv_setup', 'key': 'tv_setup', 'icon': Icons.tv},
        {'title': 'cctv', 'key': 'cctv', 'icon': Icons.videocam},
        {'title': 'wifi', 'key': 'wifi', 'icon': Icons.wifi},
        {'title': 'home_automation', 'key': 'home_automation', 'icon': Icons.settings_remote},
        {'title': 'solar_installers', 'key': 'solar_installers', 'icon': Icons.solar_power},
      ],
    },
    {
      'categoryKey': 'community_skills',
      'services': [
        {'title': 'tutor', 'key': 'tutor', 'icon': Icons.school},
        {'title': 'yoga_trainer', 'key': 'yoga_trainer', 'icon': Icons.self_improvement},
        {'title': 'music_teacher', 'key': 'music_teacher', 'icon': Icons.music_note},
        {'title': 'event_assistant', 'key': 'event_assistant', 'icon': Icons.event},
        {'title': 'errand_helper', 'key': 'errand_helper', 'icon': Icons.run_circle},
      ],
    },
  ];

  final Set<String> _selectedSkills = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: BilingualText(textKey: 'select_skills_title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20),
                  itemCount: _allServiceCategories.length,
                  itemBuilder: (context, index) {
                    final category = _allServiceCategories[index];
                    final services = category['services'] as List<Map<String, dynamic>>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ExpansionTile(
                        title: BilingualText(
                          textKey: category['categoryKey'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        children: services.map((service) {
                          return CheckboxListTile(
                            activeColor: AppColors.primaryColor,
                            title: BilingualText(textKey: service['title']!),
                            secondary: Icon(service['icon'] as IconData?, color: AppColors.primaryColor),
                            value: _selectedSkills.contains(service['key']!),
                            onChanged: (selected) => _onSkillSelected(selected, service['key']!),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueToNextStep,
                  child: const BilingualText(textKey: 'next', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
