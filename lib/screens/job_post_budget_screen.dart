import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/job_service.dart';
import 'package:setulink_app/services/price_calculator_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';

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

class _JobPostBudgetScreenState extends State<JobPostBudgetScreen> {
  QueryDocumentSnapshot? _selectedProblem;
  double _calculatedPrice = 0;
  bool _isPeakTime = false;
  bool _isLoading = false;
  final JobService _jobService = JobService();
  List<QueryDocumentSnapshot> _problems = [];

  @override
  void initState() {
    super.initState();
    _fetchProblems();
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('you_must_be_logged_in'))));
      setState(() => _isLoading = false);
      return;
    }

    if (_selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('please_select_a_problem'))));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('job_posted_successfully'))));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CitizenHome(initialIndex: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed_to_post_job')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final breakdown = _selectedProblem != null
        ? PriceCalculatorService.getPriceBreakdown(
            totalPrice: _calculatedPrice,
            problemData: _selectedProblem!.data() as Map<String, dynamic>,
          )
        : <String, double>{};
    
    return Scaffold(
      appBar: AppBar(title: Text(tr('price_summary'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('₹${_calculatedPrice.toStringAsFixed(0)}', 
                         style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    Text(tr('total_estimated_price')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_problems.isNotEmpty)
              DropdownButtonFormField<QueryDocumentSnapshot>(
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
                  labelText: tr('select_problem'),
                  border: const OutlineInputBorder(),
                ),
              ),
            
            if (_selectedProblem != null)
              ExpansionTile(
                title: Text(tr('price_breakdown')),
                children: breakdown.entries.map((e) => ListTile(
                  title: Text(tr(e.key.replaceAll('_', ' ').toLowerCase())),
                  trailing: Text('₹${e.value.toStringAsFixed(0)}'),
                )).toList(),
              ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: _isLoading ? null : _confirmBooking,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('${tr('book_now')} ₹${_calculatedPrice.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }
}
