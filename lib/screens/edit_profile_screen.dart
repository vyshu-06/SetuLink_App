import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/screens/craftizen_home.dart';

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
        // Navigate to CraftizenHome if this is the first time setup (e.g., from registration)
        // Or just pop if editing.
        // Since we are reusing this screen, we can check if we can pop.
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
      appBar: AppBar(title: const Text('Edit Professional Profile')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Set up your professional details to get better job matches.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _experienceController,
                    decoration: const InputDecoration(labelText: 'Years of Experience', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _radiusController,
                    decoration: const InputDecoration(labelText: 'Service Radius (km)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minChargeController,
                    decoration: const InputDecoration(labelText: 'Minimum Charge (₹)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
