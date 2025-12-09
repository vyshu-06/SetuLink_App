import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'chat_list_screen.dart';
import 'greeting_page.dart';
import 'profile_screen.dart';
import 'payment_screen.dart';
import 'job_request_screen.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const _HomeTabPage(),
    const _BookingsTabPage(),
    const ChatListScreen(),
    const PaymentScreen(category: 'wallet_topup'), 
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService().signOut();
    if (!mounted) return;
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
  const _HomeTabPage();

  @override
  State<_HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<_HomeTabPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allServiceCategories = [
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

  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _allServiceCategories;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCategories = _allServiceCategories;
      } else {
        _filteredCategories = _allServiceCategories.map((category) {
          final filteredServices = (category['services'] as List<Map<String, dynamic>>).where((service) {
            final title = context.tr(service['titleKey']).toLowerCase();
            return title.contains(_searchQuery);
          }).toList();

          if (filteredServices.isNotEmpty) {
            return {...category, 'services': filteredServices};
          } else {
            return null;
          }
        }).whereType<Map<String, dynamic>>().toList();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _Header(searchController: _searchController),
        const SizedBox(height: 24),
        ..._filteredCategories.map((c) => _CategorySection(category: c)).toList(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  const _Header({required this.searchController});

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
            controller: searchController,
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
  const _CategorySection({required this.category});

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
  const _BookingsTabPage();

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Job History / Bookings List using JobService
    return const Center(
      child: BilingualText(textKey: 'bookings_page_title'),
    );
  }
}
