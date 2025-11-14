import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';
import 'greeting_page.dart';
import 'profile_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({Key? key}) : super(key: key);

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeTabPage(),
    _BookingsTabPage(),
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
        title: const BilingualText(textKey: 'citizen_dashboard'),
        backgroundColor: Colors.teal,
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
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: context.tr('bookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: context.tr('chats'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeTabPage extends StatelessWidget {
  const _HomeTabPage({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: serviceCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _Header();
        }
        final category = serviceCategories[index - 1];
        return _CategorySection(category: category);
      },
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
                    // TODO: Implement service booking logic
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
    return const Center(
      child: BilingualText(textKey: 'bookings_page_title'),
    );
  }
}
