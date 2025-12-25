import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/citizen_home.dart';

class CitizenProfileSetupScreen extends StatefulWidget {
  const CitizenProfileSetupScreen({super.key});

  @override
  State<CitizenProfileSetupScreen> createState() => _CitizenProfileSetupScreenState();
}

class _CitizenProfileSetupScreenState extends State<CitizenProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'profileCompleted': true,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CitizenHome()),
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
      appBar: AppBar(title: Text(tr('complete_your_profile'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                tr('tell_us_your_location'),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: tr('city_town'), border: const OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? tr('required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(labelText: tr('pincode'), border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.length != 6 ? tr('enter_valid_pincode') : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(tr('save_and_continue'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
