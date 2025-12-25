import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/job_post_budget_screen.dart';
import 'package:intl/intl.dart';

class JobRequestScreen extends StatefulWidget {
  final String? category;
  const JobRequestScreen({Key? key, this.category}) : super(key: key);

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  Future<void> _proceedToPricing() async {
    setState(() => _isLoading = true);

    try {
      final serviceId = widget.category?.toLowerCase().replaceAll(' ', '_') ?? 'general_service';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobPostBudgetScreen(
              serviceId: serviceId,
              scheduledTime: _selectedDate,
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
      appBar: AppBar(title: Text(tr('schedule_your_service')), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text("${tr('service')}: ${widget.category ?? 'N/A'}"),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text("${tr('scheduled_for')}: ${DateFormat('dd MMM, yyyy').format(_selectedDate)}"),
              trailing: const Icon(Icons.calendar_today),
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _proceedToPricing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(tr('proceed_to_select_problem'), style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
