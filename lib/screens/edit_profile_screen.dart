import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/screens/craftizen_home.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _radiusController = TextEditingController();
  final _minChargeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _experienceController.text = (data['experienceYears'] ?? '').toString();
        _radiusController.text = (data['serviceRadiusKm'] ?? '').toString();
        _minChargeController.text = (data['minCharge'] ?? '').toString();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'serviceRadiusKm': int.tryParse(_radiusController.text) ?? 5,
        'minCharge': double.tryParse(_minChargeController.text) ?? 0.0,
        'profileCompleted': true, // Mark profile as completed
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CraftizenHome()),
          );
        }
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
      appBar: AppBar(title: const BilingualText(textKey: 'Edit Professional Profile')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const BilingualText(
                    textKey: 'Complete', // Using complete as placeholder for setup message
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _experienceController,
                    decoration: InputDecoration(
                      label: const BilingualText(textKey: 'Complete'), // Placeholder
                      border: const OutlineInputBorder()
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? tr('Please enter a value') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _radiusController,
                    decoration: InputDecoration(
                      label: const BilingualText(textKey: 'km away'), // Placeholder
                      border: const OutlineInputBorder()
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? tr('Please enter a value') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minChargeController,
                    decoration: InputDecoration(
                      label: const BilingualText(textKey: 'Amount'), // Placeholder
                      border: const OutlineInputBorder()
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? tr('Please enter a value') : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const BilingualText(textKey: 'Complete'),
                  ),
                ],
              ),
            ),
    );
  }
}
