import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:setulink_app/screens/greeting_page.dart';
import 'package:setulink_app/screens/kyc_screen.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _currentUser; 

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _currentUser != null) {
      final String userId = _currentUser!['uid'];
      final File imageFile = File(image.path);

      try {
        // Create a reference to the location you want to upload to
        final ref = FirebaseStorage.instance.ref('profile_pictures/$userId');

        // Upload the file
        await ref.putFile(imageFile);

        // Get the download URL
        final String downloadUrl = await ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profilePictureUrl': downloadUrl,
        });

        // Refresh user data
        setState(() {
          _currentUser!['profilePictureUrl'] = downloadUrl;
        });

        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));

      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
    if(mounted) {
       Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const GreetingPage()),
        (route) => false,
      );
    }
  }

  void _handleSwitchAccount() {
     // This is the same as logout, as there is no multi-account management yet
    _handleLogout();
  }

  @override
  Widget build(BuildContext context) {
    final String name = _currentUser?['name'] ?? 'N/A';
    final String email = _currentUser?['email'] ?? 'N/A';
    final String phone = _currentUser?['phone'] ?? 'N/A';
    final String role = _currentUser?['role'] ?? 'N/A';
    final String? profilePictureUrl = _currentUser?['profilePictureUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const BilingualText(textKey: 'profile'),
        backgroundColor: role == 'citizen' ? Colors.teal : (role == 'admin' ? Colors.blueGrey : Colors.deepOrange),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Stack(
              children: [
                _ProfilePicture(profilePictureUrl: profilePictureUrl),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.teal),
                      onPressed: _pickAndUploadImage,
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(icon: Icons.person, text: name),
          _buildInfoCard(icon: Icons.email, text: email),
          _buildInfoCard(icon: Icons.phone, text: phone),
          _buildInfoCard(icon: Icons.work, text: role.toUpperCase()),
          const SizedBox(height: 24),
          if (role == 'craftizen') ...[
            _buildOptionButton(context, text: 'Verify KYC', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KYCScreen()))),
            _buildOptionButton(context, text: 'Subscription Plans', onTap: () => Navigator.pushNamed(context, '/subscription_plans')),
          ],
          const Divider(),
          _buildOptionTile(context, icon: Icons.logout, text: 'Logout', onTap: _handleLogout),
          _buildOptionTile(context, icon: Icons.switch_account, text: 'Switch Accounts', onTap: _handleSwitchAccount),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {required String text, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.teal,
          side: const BorderSide(color: Colors.teal),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text),
      onTap: onTap,
    );
  }
}

// New widget to manage profile picture display
class _ProfilePicture extends StatelessWidget {
  final String? profilePictureUrl;
  const _ProfilePicture({this.profilePictureUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl!) : null,
      child: profilePictureUrl == null ? const Icon(Icons.person, size: 50) : null,
    );
  }
}
