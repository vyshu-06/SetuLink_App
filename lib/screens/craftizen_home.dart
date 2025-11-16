import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';
import 'greeting_page.dart';
import 'profile_screen.dart';

class CraftizenHome extends StatefulWidget {
  const CraftizenHome({Key? key}) : super(key: key);

  @override
  State<CraftizenHome> createState() => _CraftizenHomeState();
}

class _CraftizenHomeState extends State<CraftizenHome> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeTabPage(),
    _JobsTabPage(),
    ChatListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const GreetingPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const BilingualText(textKey: 'craftizen_dashboard'),
        backgroundColor: Colors.deepOrange,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _navigateToProfile,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: BilingualText(textKey: 'logout'),
              ),
            ],
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.work_outline),
            activeIcon: const Icon(Icons.work),
            label: context.tr('jobs'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: context.tr('chats'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeTabPage extends StatelessWidget {
  const _HomeTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final String uid = currentUser?['uid'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final String name = userData?['name'] ?? '';
        final List<String> skills = (userData?['skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final bool isKycVerified = userData?['kyc']?['verified'] ?? false;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Column(
                  children: [
                    BilingualText(
                      textKey: 'welcome_craftizen',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSkillsSection(skills),
            ),
            SliverToBoxAdapter(
              child: _buildJobsSection(isKycVerified),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillsSection(List<String> skills) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BilingualText(
            textKey: 'my_skills',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: skills
                .map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.deepOrange.shade50,
                      labelStyle: TextStyle(color: Colors.deepOrange.shade800),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSection(bool isKycVerified) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BilingualText(
            textKey: 'job_requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: isKycVerified
                  ? const BilingualText(
                      textKey: 'no_jobs_available',
                      style: TextStyle(color: Colors.grey),
                    )
                  : const BilingualText(
                      textKey: 'kyc_not_verified_message',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobsTabPage extends StatelessWidget {
  const _JobsTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: BilingualText(textKey: 'jobs_page_title'),
    );
  }
}
