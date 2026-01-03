import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/greeting_page.dart';
import 'package:setulink_app/screens/kyc_screen.dart';
import 'package:setulink_app/services/auth_service.dart' as app_auth;
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final app_auth.AuthService _authService = app_auth.AuthService();
  User? _authUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

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
  }

  Future<void> _loadUserData() async {
    _authUser = _authService.getCurrentUser();
    if (_authUser != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_authUser!.uid).get();
        if (mounted) {
           setState(() {
             _userData = doc.data() as Map<String, dynamic>?;
             _isLoading = false;
           });
           _animationController.forward();
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && _authUser != null) {
      final String userId = _authUser!.uid;
      final File imageFile = File(image.path);

      try {
        final ref = FirebaseStorage.instance.ref('profile_pictures/$userId');
        await ref.putFile(imageFile);
        final String downloadUrl = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profilePictureUrl': downloadUrl,
        });

        setState(() {
          if (_userData != null) {
            _userData!['profilePictureUrl'] = downloadUrl;
          }
        });

        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('profile_picture_updated'))));

      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('failed_to_upload_image')}: $e')));
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
    _handleLogout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildProfileContent(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final String name = _userData?['name'] ?? 'N/A';
    final String email = _userData?['email'] ?? 'N/A';
    final String phone = _userData?['phone'] ?? 'N/A';
    final String role = _userData?['role'] ?? 'N/A';
    final String? profilePictureUrl = _userData?['profilePictureUrl'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Stack(
            children: [
              _ProfilePicture(profilePictureUrl: profilePictureUrl),
              Positioned(
                bottom: 0,
                right: 4,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.accentColor,
                    child: Icon(Icons.edit, size: 22, color: Colors.black),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Text(role.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontStyle: FontStyle.italic)),
        ),
        const SizedBox(height: 32),
        _buildInfoCard(icon: Icons.email, text: email),
        _buildInfoCard(icon: Icons.phone, text: phone),
        const SizedBox(height: 24),
        if (role == 'craftizen') ...[
          _buildOptionButton(context, textKey: 'verify_kyc', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KYCScreen()))),
          _buildOptionButton(context, textKey: 'subscription_plans', onTap: () => Navigator.pushNamed(context, '/subscription_plans')),
        ],
        const Divider(color: Colors.white54, thickness: 1, indent: 20, endIndent: 20),
        _buildOptionTile(context, icon: Icons.logout, textKey: 'logout', onTap: _handleLogout),
        _buildOptionTile(context, icon: Icons.switch_account, textKey: 'switch_accounts', onTap: _handleSwitchAccount),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor),
        title: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {required String textKey, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton(
        onPressed: onTap,
        child: BilingualText(textKey: textKey, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String textKey, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: BilingualText(textKey: textKey, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _ProfilePicture extends StatelessWidget {
  final String? profilePictureUrl;
  const _ProfilePicture({this.profilePictureUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 57,
        backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl!) : null,
        child: profilePictureUrl == null ? const Icon(Icons.person, size: 60, color: AppColors.primaryColor) : null,
      ),
    );
  }
}
