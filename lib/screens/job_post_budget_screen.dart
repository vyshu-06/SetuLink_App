import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/job_service.dart';
import 'package:setulink_app/services/price_calculator_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class JobPostBudgetScreen extends StatefulWidget {
  final String serviceId;
  final String? craftizenId; // optional specific Craftizen
  final DateTime scheduledTime;

  const JobPostBudgetScreen({
    super.key,
    required this.serviceId,
    this.craftizenId,
    required this.scheduledTime,
  });

  @override
  State<JobPostBudgetScreen> createState() => _JobPostBudgetScreenState();
}

class _JobPostBudgetScreenState extends State<JobPostBudgetScreen> with SingleTickerProviderStateMixin {
  QueryDocumentSnapshot? _selectedProblem;
  double _calculatedPrice = 0;
  bool _isPeakTime = false;
  bool _isLoading = false;
  final JobService _jobService = JobService();
  List<QueryDocumentSnapshot> _problems = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchProblems();

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

  void _fetchProblems() async {
    _problems = await PriceCalculatorService.getProblemsForService(widget.serviceId);
    if (_problems.isNotEmpty) {
      setState(() {
        _selectedProblem = _problems.first;
        _calculatePrice();
      });
    }
  }

  void _calculatePrice() async {
    if (_selectedProblem == null) return;

    double price = await PriceCalculatorService.calculateServicePrice(
      problemData: _selectedProblem!.data() as Map<String, dynamic>,
      isPeakTime: _isPeakTime,
    );
    setState(() => _calculatedPrice = price);
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('You must be logged in'))));
      setState(() => _isLoading = false);
      return;
    }

    if (_selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Please select a problem'))));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final problemData = _selectedProblem!.data() as Map<String, dynamic>;
      final newJob = JobModel(
        id: FirebaseFirestore.instance.collection('jobs').doc().id,
        userId: currentUser.uid,
        title: problemData['title'] ?? 'Job',
        description: problemData['description'] ?? '',
        budget: _calculatedPrice,
        scheduledTime: widget.scheduledTime,
        location: const GeoPoint(0, 0), // MOCK location
        requiredSkills: [widget.serviceId], // MOCK skills
        images: [], // MOCK images
        assignedTo: widget.craftizenId,
      );

      await _jobService.createJob(newJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Job posted successfully'))));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CitizenHome(initialIndex: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Failed to post job')}: $e')));
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
        title: const BilingualText(textKey: 'SetuLink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Changed title
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const BilingualText(textKey: 'Amount', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 10),
                            Text('₹${_calculatedPrice.toStringAsFixed(0)}', 
                                 style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_problems.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: DropdownButtonFormField<QueryDocumentSnapshot>(
                            value: _selectedProblem,
                            items: _problems.map((problem) {
                              final problemData = problem.data() as Map<String, dynamic>;
                              return DropdownMenuItem<QueryDocumentSnapshot>(
                                value: problem,
                                child: Text(problemData['title'] ?? 'N/A'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProblem = value;
                                _calculatePrice();
                              });
                            },
                            decoration: InputDecoration(
                              label: const BilingualText(textKey: 'Service'),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmBooking,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const BilingualText(textKey: 'Pay Now'), // Placeholder
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
