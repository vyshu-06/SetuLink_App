import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/job_service.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';
import 'greeting_page.dart';
import 'profile_screen.dart';
import 'job_detail_screen.dart';
import 'edit_profile_screen.dart';

class CraftizenHome extends StatefulWidget {
  const CraftizenHome({Key? key}) : super(key: key);

  @override
  State<CraftizenHome> createState() => _CraftizenHomeState();
}

class _CraftizenHomeState extends State<CraftizenHome> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const _HomeTabPage(),
    const _JobsTabPage(),
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const BilingualText(textKey: 'craftizen_dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: _navigateToProfile,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _pages.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 5)],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Chats'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTabPage extends StatelessWidget {
  const _HomeTabPage({Key? key}) : super(key: key);

  void _toggleAvailability(String uid, bool currentStatus) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isAvailable': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final String uid = currentUser?.uid ?? '';

    return SafeArea(
      bottom: false,
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final String name = userData?['name'] ?? '';
          final List<String> skills = (userData?['skills'] as List<dynamic>?)?.cast<String>() ?? [];
          final bool isKycVerified = userData?['kyc']?['verified'] ?? false;
          final bool isAvailable = userData?['isAvailable'] ?? false;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, kToolbarHeight, 16.0, 16.0),
                  child: Column(
                    children: [
                      const BilingualText(
                        textKey: 'welcome_craftizen',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: isAvailable ? Colors.greenAccent : Colors.white54),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BilingualText(textKey: isAvailable ? 'available_for_work' : 'not_available', style: TextStyle(color: isAvailable ? Colors.white : Colors.white70, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Switch(
                              value: isAvailable,
                              activeColor: Colors.greenAccent,
                              onChanged: (val) => _toggleAvailability(uid, isAvailable),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 20),
                        label: const BilingualText(textKey: 'edit_professional_profile'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSkillsSection(skills, context),
              ),
              SliverToBoxAdapter(
                child: _buildJobsSection(context, isKycVerified, skills),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkillsSection(List<String> skills, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              textKey: 'my_skills',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              const Center(child: BilingualText(textKey: 'no_skills_added'))
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: skills.map((skill) => Chip(label: Text(skill), backgroundColor: AppColors.primaryColor.withOpacity(0.1))).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsSection(BuildContext context, bool isKycVerified, List<String> skills) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              textKey: 'job_requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 12),
            if (!isKycVerified)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: BilingualText(
                    textKey: 'kyc_not_verified_jobs',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (skills.isEmpty)
              const Center(child: BilingualText(textKey: 'add_skills_to_see_jobs'))
            else
              const Center(child: BilingualText(textKey: 'go_to_jobs_tab')),
          ],
        ),
      ),
    );
  }
}

class _JobsTabPage extends StatelessWidget {
  const _JobsTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top),
            Container(
              color: Colors.white.withOpacity(0.1),
              child: const TabBar(
                tabs: [
                  Tab(child: BilingualText(textKey: 'new_jobs')),
                  Tab(child: BilingualText(textKey: 'my_jobs')),
                ],
                indicatorColor: AppColors.accentColor,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _NewJobsList(),
                  _MyJobsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewJobsList extends StatelessWidget {
  const _NewJobsList();

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final String uid = currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final List<String> skills = (userData?['skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final bool isKycVerified = userData?['kyc']?['verified'] ?? false;

        if (!isKycVerified) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.orangeAccent),
                SizedBox(height: 16),
                BilingualText(textKey: 'kyc_not_verified_jobs', style: TextStyle(color: Colors.white), textAlign: TextAlign.center,),
              ],
            ),
          );
        }

        if (skills.isEmpty) {
          return const Center(child: BilingualText(textKey: 'add_skills_to_see_jobs', style: TextStyle(color: Colors.white)));
        }

        return StreamBuilder<List<JobModel>>(
          stream: JobService().getOpenJobsForCraftizen(skills),
          builder: (context, jobSnapshot) {
            if (jobSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
            if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) return const Center(child: BilingualText(textKey: 'no_new_jobs_nearby', style: TextStyle(color: Colors.white)));

            final jobs = jobSnapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: jobs.length,
              itemBuilder: (context, index) => _JobCard(job: jobs[index]),
            );
          },
        );
      },
    );
  }
}

class _MyJobsList extends StatelessWidget {
  const _MyJobsList();

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().getCurrentUser();
    final String uid = currentUser?.uid ?? '';

    return StreamBuilder<List<JobModel>>(
      stream: JobService().getJobsStream(uid, isCraftizen: true),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
        if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) return const Center(child: BilingualText(textKey: 'no_accepted_jobs_yet', style: TextStyle(color: Colors.white)));

        final jobs = jobSnapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: jobs.length,
          itemBuilder: (context, index) => _JobCard(job: jobs[index]),
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget: ₹${job.budget}'),
            Text('Status: ${job.jobStatus.toUpperCase()}', style: TextStyle(color: job.jobStatus == 'open' ? Colors.green : Colors.blue)),
            Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primaryColor),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))),
      ),
    );
  }
}
