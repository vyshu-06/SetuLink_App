import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/job_service.dart';
import 'package:setulink_app/screens/recommendation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class JobRequestScreen extends StatefulWidget {
  final String? category; // Pre-filled category from Home
  const JobRequestScreen({Key? key, this.category}) : super(key: key);

  @override
  _JobRequestScreenState createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  int _currentStep = 0;
  final _formKeyDetails = GlobalKey<FormState>();
  final _formKeyTime = GlobalKey<FormState>();
  final _formKeyBudget = GlobalKey<FormState>();

  // Step 1: Details
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  String? _recordedVoicePath;

  // Step 2: When & Where
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _addressController = TextEditingController();

  // Step 3: Budget & Confirmation
  final TextEditingController _budgetController = TextEditingController();
  bool _allowNegotiation = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _titleController.text = "Looking for ${widget.category}";
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _images.add(image));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitJob() async {
    if (!_formKeyBudget.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    setState(() => _isLoading = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final job = JobModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: _titleController.text,
      description: _descController.text,
      budget: double.tryParse(_budgetController.text) ?? 0.0,
      scheduledTime: scheduledDateTime,
      location: const GeoPoint(0, 0), // Mock
      requiredSkills: widget.category != null ? [widget.category!] : [],
      images: _images.map((e) => e.path).toList(),
      voiceUrl: _recordedVoicePath,
      jobStatus: 'open',
      preferences: {'allowNegotiation': _allowNegotiation},
    );

    await JobService().createJob(job);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RecommendationScreen(job: job)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job'), backgroundColor: Colors.teal),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0) {
            if (_formKeyDetails.currentState!.validate()) setState(() => _currentStep++);
          } else if (_currentStep == 1) {
            if (_formKeyTime.currentState!.validate()) setState(() => _currentStep++);
          } else {
            _submitJob();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep < 2)
                  Expanded(child: ElevatedButton(onPressed: details.onStepContinue, child: const Text('Next')))
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm & Post', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('Back'))),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Details'),
            content: Form(
              key: _formKeyDetails,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickImage),
                      IconButton(icon: Icon(_isRecording ? Icons.stop : Icons.mic), onPressed: () => setState(() => _isRecording = !_isRecording)),
                      if (_images.isNotEmpty) Text('${_images.length} photos'),
                    ],
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Time/Loc'),
            content: Form(
              key: _formKeyTime,
              child: Column(
                children: [
                  ListTile(
                    title: Text("Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  ListTile(
                    title: Text("Time: ${_selectedTime.format(context)}"),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address/Location', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Confirm'),
            content: Form(
              key: _formKeyBudget,
              child: Column(
                children: [
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Budget (₹)', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Allow Negotiation'),
                    value: _allowNegotiation,
                    onChanged: (v) => setState(() => _allowNegotiation = v),
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
