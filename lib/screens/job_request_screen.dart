import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/screens/job_post_budget_screen.dart';
import 'package:intl/intl.dart';

class JobRequestScreen extends StatefulWidget {
  final String? category;
  const JobRequestScreen({Key? key, this.category}) : super(key: key);

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _titleController.text = "Looking for a ${widget.category}";
    }
  }

  Future<void> _proceedToPricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // For simplicity, we are using a fixed serviceId based on category
      // In a real app, you would have a more complex mapping
      final serviceId = widget.category?.toLowerCase().replaceAll(' ', '_');
      if (serviceId == null) throw Exception('Category not defined');

      final serviceDoc = await FirebaseFirestore.instance.collection('services').doc(serviceId).get();
      if (!serviceDoc.exists || serviceDoc.data() == null) {
        throw Exception('Service details not found in database.');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobPostBudgetScreen(
              serviceId: serviceId,
              serviceData: serviceDoc.data()!,
              jobTitle: _titleController.text,
              jobDescription: _descController.text,
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
      appBar: AppBar(title: const Text('Describe Your Job'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Job Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Describe what you need done', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please provide a description' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("Scheduled for: ${DateFormat('dd MMM, yyyy').format(_selectedDate)}"),
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
                    : const Text('Proceed to Pricing', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
