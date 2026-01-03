import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/craftizen_common_questions_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class CraftizenExperienceScreen extends StatefulWidget {
  final String userId;
  final List<String> selectedSkills;

  const CraftizenExperienceScreen({required this.userId, required this.selectedSkills, Key? key})
      : super(key: key);

  @override
  State<CraftizenExperienceScreen> createState() => _CraftizenExperienceScreenState();
}

class _CraftizenExperienceScreenState extends State<CraftizenExperienceScreen> with SingleTickerProviderStateMixin {
  String? _experience;
  String? _radius;
  String? _isCertified;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'tell_us_more', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          const SizedBox(height: 50),
                          _buildDropdown(
                            label: tr('how_many_years_experience'),
                            value: _experience,
                            items: ['0-1', '1-3', '3-5', '5+'],
                            onChanged: (val) => setState(() => _experience = val),
                          ),
                          const SizedBox(height: 24),
                          _buildDropdown(
                            label: tr('mention_travel_radius'),
                            value: _radius,
                            items: ['5 km', '10 km', '25 km', '50 km+'],
                            onChanged: (val) => setState(() => _radius = val),
                          ),
                          const SizedBox(height: 24),
                          _buildDropdown(
                            label: tr('are_you_certified'),
                            value: _isCertified,
                            items: ['Yes', 'No'],
                            onChanged: (val) => setState(() => _isCertified = val),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _saveAndContinue,
                            child: const BilingualText(textKey: 'next', style: TextStyle(fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDropdown({required String label, String? value, required List<String> items, ValueChanged<String?>? onChanged}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            filled: false,
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(tr(item)))).toList(),
          onChanged: onChanged,
          validator: (val) => val == null ? tr('please_select_an_option') : null,
        ),
      ),
    );
  }
}
