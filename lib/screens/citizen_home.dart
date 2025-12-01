import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/models/craftizen_model.dart';
import 'package:setulink_app/services/analytics_service.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/recommendation_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';
import 'greeting_page.dart';
import 'profile_screen.dart';
import 'payment_screen.dart';
import 'craftizen_profile_view_screen.dart';
import 'job_request_screen.dart';

final AnalyticsService _analyticsService = AnalyticsService();

class CitizenHome extends StatefulWidget {
  const CitizenHome({Key? key}) : super(key: key);

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _selectedIndex = 0;

  // Pages for the bottom nav. Note: Wallet/Profile might just navigate directly.
  // For simplicity in standard BottomNav structure, we can use placeholders or direct navigation logic.
  // However, standard pattern is to have widgets for each tab.
  static final List<Widget> _pages = <Widget>[
    const _HomeTabPage(),
    const _BookingsTabPage(),
    const ChatListScreen(),
    const PaymentScreen(category: 'wallet_topup'), // Placeholder for Wallet
    const ProfileScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const BilingualText(textKey: 'citizen_dashboard'),
        backgroundColor: Colors.teal,
        elevation: 1,
        actions: [
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
        type: BottomNavigationBarType.fixed, // Needed for 4+ items
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: context.tr('bookings'), // "Jobs" in prompt, usually means bookings
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: context.tr('chats'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.tr('profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const JobRequestScreen()));
        },
        label: const Text('Post a Job'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ) : null,
    );
  }
}

class _HomeTabPage extends StatefulWidget {
  const _HomeTabPage({Key? key}) : super(key: key);

  @override
  State<_HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<_HomeTabPage> {
  static final List<Map<String, dynamic>> serviceCategories = [
    {
      'categoryKey': 'everyday_needs',
      'services': [
        {'titleKey': 'plumber', 'icon': Icons.plumbing},
        {'titleKey': 'electrician', 'icon': Icons.electrical_services},
        {'titleKey': 'carpenter', 'icon': Icons.handyman},
        {'titleKey': 'house_cleaner', 'icon': Icons.cleaning_services},
        {'titleKey': 'gardener', 'icon': Icons.local_florist},
        {'titleKey': 'tailor', 'icon': Icons.cut},
        {'titleKey': 'painter', 'icon': Icons.format_paint},
        {'titleKey': 'babysitter', 'icon': Icons.child_friendly},
        {'titleKey': 'laundry', 'icon': Icons.local_laundry_service},
        {'titleKey': 'elderly_caregiver', 'icon': Icons.elderly},
        {'titleKey': 'pet_care', 'icon': Icons.pets},
        {'titleKey': 'driver', 'icon': Icons.drive_eta},
      ],
    },
    {
      'categoryKey': 'semi_technical',
      'services': [
        {'titleKey': 'mobile_repair', 'icon': Icons.phonelink_setup},
        {'titleKey': 'appliance_repair', 'icon': Icons.build_circle},
        {'titleKey': 'tv_setup', 'icon': Icons.tv},
        {'titleKey': 'cctv', 'icon': Icons.videocam},
        {'titleKey': 'wifi', 'icon': Icons.wifi},
        {'titleKey': 'home_automation', 'icon': Icons.settings_remote},
        {'titleKey': 'solar_installers', 'icon': Icons.solar_power},
      ],
    },
    {
      'categoryKey': 'community_skills',
      'services': [
        {'titleKey': 'tutor', 'icon': Icons.school},
        {'titleKey': 'yoga_trainer', 'icon': Icons.self_improvement},
        {'titleKey': 'music_teacher', 'icon': Icons.music_note},
        {'titleKey': 'event_assistant', 'icon': Icons.event},
        {'titleKey': 'errand_helper', 'icon': Icons.run_circle},
      ],
    },
  ];

  Future<List<CraftizenModel>>? _recommendations;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    // In real app, get current GPS location
    // For now, mock location (0,0) or some default
    final mockLocation = const GeoPoint(0, 0); 
    _recommendations = RecommendationService().getRecommendedCraftizens(mockLocation);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const _Header(),
        _buildRecommendedSection(),
        ...serviceCategories.map((c) => _CategorySection(category: c)).toList(),
      ],
    );
  }

  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Text('Recommended Craftizens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 160,
          child: FutureBuilder<List<CraftizenModel>>(
            future: _recommendations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No recommendations yet'));

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final craftizen = snapshot.data![index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CraftizenProfileViewScreen(craftizenId: craftizen.uid)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(child: Text(craftizen.name[0])),
                              const SizedBox(height: 8),
                              Text(craftizen.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                Text(craftizen.rating.toStringAsFixed(1)),
                              ]),
                              Text(craftizen.skills.firstOrNull ?? 'Craftizen', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
      child: Column(
        children: [
          BilingualText(
            textKey: 'welcome_citizen',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
          ),
          const SizedBox(height: 8),
          BilingualText(
            textKey: 'what_service_looking_for',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: context.tr('search_services'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategorySection({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final services = category['services'] as List<Map<String, dynamic>>;
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: BilingualText(
              textKey: category['categoryKey']!,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: services.length,
            itemBuilder: (context, serviceIndex) {
              final service = services[serviceIndex];
              return Card(
                elevation: 3.0,
                shadowColor: Colors.black.withAlpha(26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    _analyticsService.logJobRequested(service['titleKey']!);
                    // Pass category to JobRequestScreen flow
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobRequestScreen(category: service['titleKey']),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade50, Colors.teal.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(service['icon'] as IconData?, size: 30, color: Colors.teal.shade800),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: BilingualText(
                          textKey: service['titleKey']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BookingsTabPage extends StatelessWidget {
  const _BookingsTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Job History / Bookings List using JobService
    return const Center(
      child: BilingualText(textKey: 'bookings_page_title'),
    );
  }
}
