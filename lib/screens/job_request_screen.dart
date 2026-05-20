import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/job_post_budget_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class JobRequestScreen extends StatefulWidget {
  final String? category;
  const JobRequestScreen({Key? key, this.category}) : super(key: key);

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'plumber', 'electrician', 'carpenter', 'house_cleaner', 'gardener', 
    'tailor', 'painter', 'babysitter', 'laundry', 'elderly_caregiver', 
    'pet_care', 'driver', 'mobile_repair', 'appliance_repair', 'tv_setup', 
    'cctv', 'wifi', 'home_automation', 'solar_installers', 'tutor', 
    'yoga_trainer', 'music_teacher', 'event_assistant', 'errand_helper'
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
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


  Future<void> _proceedToPricing() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BilingualText(textKey: 'please_select_service')),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BilingualText(textKey: 'please_enter_description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final serviceId = _selectedCategory!.toLowerCase().replaceAll(' ', '_');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobPostBudgetScreen(
              serviceId: serviceId,
              scheduledTime: _selectedDate,
              description: _descriptionController.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'schedule_your_service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: const BilingualText(textKey: 'service'),
                              subtitle: widget.category != null 
                                ? BilingualText(textKey: widget.category!, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor))
                                : DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    hint: const BilingualText(textKey: 'select_service'),
                                    items: _categories.map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: BilingualText(textKey: cat),
                                    )).toList(),
                                    onChanged: (val) => setState(() => _selectedCategory = val),
                                  ),
                            ),
                            const Divider(),
                            ListTile(
                              title: const BilingualText(textKey: 'scheduled_for'),
                              subtitle: Text(DateFormat('dd MMM, yyyy').format(_selectedDate), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                              trailing: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (pickedDate != null) setState(() => _selectedDate = pickedDate);
                              },
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  label: const BilingualText(textKey: 'job_description'),
                                  hintText: tr('describe_what_needs_to_be_done'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _proceedToPricing,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const BilingualText(textKey: 'proceed_to_select_problem', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
