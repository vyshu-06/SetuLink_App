import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/job_service.dart';
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
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: const Text('Craftizen Dashboard'),
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
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
        body: _pages.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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
        final bool isAvailable = userData?['isAvailable'] ?? false;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
                child: Column(
                  children: [
                    Text(
                      'Welcome, Craftizen!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Availability Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: isAvailable ? Colors.green : Colors.grey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isAvailable ? 'Available for Work' : 'Not Available', style: TextStyle(color: isAvailable ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Switch(
                            value: isAvailable,
                            activeColor: Colors.green,
                            onChanged: (val) => _toggleAvailability(uid, isAvailable),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Professional Profile'),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
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
          ],
        );
      },
    );
  }

  Widget _buildSkillsSection(List<String> skills, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Skills',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: skills
                .map((skill) => Chip(
                      label: Text(skill),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSection(BuildContext context, bool isKycVerified, List<String> skills) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (!isKycVerified)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'Your KYC is not verified. Please complete KYC to see job requests.',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (skills.isEmpty)
             const Center(child: Text('Add skills to see relevant jobs'))
          else
             // Sneak peek or shortcut
             const Center(child: Text('Go to "Jobs" tab to find work!')),
        ],
      ),
    );
  }
}

class _JobsTabPage extends StatelessWidget {
  const _JobsTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'New Jobs'),
              Tab(text: 'My Jobs'),
            ],
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
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final List<String> skills = (userData?['skills'] as List<dynamic>?)?.cast<String>() ?? [];
        final bool isKycVerified = userData?['kyc']?['verified'] ?? false;

        if (!isKycVerified) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Your KYC is not verified. Please complete KYC to see job requests.'),
              ],
            ),
          );
        }

        if (skills.isEmpty) {
          return const Center(child: Text('Please add skills to your profile to see jobs.'));
        }

        return StreamBuilder<List<JobModel>>(
          stream: JobService().getOpenJobsForCraftizen(skills),
          builder: (context, jobSnapshot) {
            if (jobSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) return const Center(child: Text('No new jobs nearby.'));

            final jobs = jobSnapshot.data!;
            return ListView.builder(
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
        if (jobSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!jobSnapshot.hasData || jobSnapshot.data!.isEmpty) return const Center(child: Text('No accepted jobs yet.'));

        final jobs = jobSnapshot.data!;
        return ListView.builder(
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: job.id))
          );
        },
      ),
    );
  }
}
