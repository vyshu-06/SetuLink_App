import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/auth_service.dart';
import 'package:setulink_app/services/job_service.dart';
import 'package:setulink_app/services/price_calculator_service.dart';
import 'package:setulink_app/services/location_service.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:setulink_app/screens/citizen_home.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class JobPostBudgetScreen extends StatefulWidget {
  final String serviceId;
  final String? craftizenId; // optional specific Craftizen
  final DateTime scheduledTime;
  final String description;

  const JobPostBudgetScreen({
    super.key,
    required this.serviceId,
    this.craftizenId,
    required this.scheduledTime,
    required this.description,
  });

  @override
  State<JobPostBudgetScreen> createState() => _JobPostBudgetScreenState();
}

class _JobPostBudgetScreenState extends State<JobPostBudgetScreen> with SingleTickerProviderStateMixin {
  QueryDocumentSnapshot? _selectedProblem;
  double _calculatedPrice = 0;
  bool _isPeakTime = false;
  bool _isLoading = false;
  final JobService _jobService = JobService();
  final LocationService _locationService = LocationService();
  final TextEditingController _addressController = TextEditingController();
  GeoPoint _currentGeoPoint = const GeoPoint(0, 0);
  String _currentCity = '';
  List<QueryDocumentSnapshot> _problems = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchProblems();
    _fetchCurrentLocation();

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchProblems() async {
    _problems = await PriceCalculatorService.getProblemsForService(widget.serviceId);
    if (_problems.isNotEmpty) {
      setState(() {
        _selectedProblem = _problems.first;
        _calculatePrice();
      });
    }
  }

  void _fetchCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching current location...'), duration: Duration(seconds: 1)),
    );

    final locationData = await _locationService.getCurrentLocation();
    if (locationData != null) {
      String? cityName;
      String? fullAddress;

      // 1. Try Native Geocoding (Mobile only)
      if (!kIsWeb) {
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            locationData.latitude!,
            locationData.longitude!,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            cityName = p.locality;
            fullAddress = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea} ${p.postalCode}";
          }
        } catch (e) {
          debugPrint('Native geocoding failed: $e');
        }
      }

      // 2. Fallback to Nominatim (Web and Mobile fallback)
      if (fullAddress == null) {
        try {
          final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${locationData.latitude}&lon=${locationData.longitude}&zoom=18&addressdetails=1');
          final response = await http.get(url, headers: {'User-Agent': 'SetuLinkApp'});
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            fullAddress = data['display_name'];
            final address = data['address'];
            cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'];
          }
        } catch (e) {
          debugPrint('Nominatim fallback failed: $e');
        }
      }

      // Clean up multiple commas or empty spaces
      if (fullAddress != null) {
        fullAddress = fullAddress.replaceAll(RegExp(r', ,'), ',').replaceAll(RegExp(r'^, '), '').trim();
      }

      if (mounted) {
        setState(() {
          _currentGeoPoint = GeoPoint(locationData.latitude!, locationData.longitude!);
          if (cityName != null) _currentCity = cityName;
          if (fullAddress != null) {
            _addressController.text = fullAddress!;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get GPS coordinates. Please ensure GPS is on and permissions are granted.')),
        );
      }
    }
  }

  void _calculatePrice() async {
    if (_selectedProblem == null) {
      setState(() => _calculatedPrice = 100.0); // Default price if no problem selected
      return;
    }

    double price = await PriceCalculatorService.calculateServicePrice(
      problemData: _selectedProblem!.data() as Map<String, dynamic>,
      isPeakTime: _isPeakTime,
    );
    setState(() => _calculatedPrice = price);
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('You must be logged in'))));
      setState(() => _isLoading = false);
      return;
    }

    if (_selectedProblem == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Please select a problem'))));
      setState(() => _isLoading = false);
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Please enter your address'))));
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Determine the best location coordinates for the job
      GeoPoint finalGeoPoint = _currentGeoPoint;
      
      // If an address is provided, prioritize geocoding it to get the correct house location
      if (_addressController.text.trim().isNotEmpty) {
        try {
          // Add Kurnool and Andhra Pradesh to the search if not present to improve local accuracy
          String searchQuery = _addressController.text.trim();
          if (!searchQuery.toLowerCase().contains('kurnool')) {
            searchQuery += ', Kurnool, Andhra Pradesh';
          }

          final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(searchQuery)}&limit=1');
          final response = await http.get(url, headers: {'User-Agent': 'SetuLinkApp'});
          
          if (response.statusCode == 200) {
            final List data = json.decode(response.body);
            if (data.isNotEmpty) {
              final lat = double.parse(data[0]['lat']);
              final lon = double.parse(data[0]['lon']);
              finalGeoPoint = GeoPoint(lat, lon);
              debugPrint('Job address resolved to: $lat, $lon');
            } else {
              debugPrint('Geocoding returned no results for: $searchQuery');
            }
          }
        } catch (e) {
          debugPrint('Geocoding search error: $e');
        }
      }

      // If we still have 0,0 (unlikely with _fetchCurrentLocation in init), use current GPS as last resort
      if (finalGeoPoint.latitude == 0 && finalGeoPoint.longitude == 0) {
        finalGeoPoint = _currentGeoPoint;
      }

      final problemData = _selectedProblem?.data() as Map<String, dynamic>?;
      final newJob = JobModel(
        id: FirebaseFirestore.instance.collection('jobs').doc().id,
        userId: currentUser.uid,
        title: problemData?['title'] ?? tr(widget.serviceId),
        description: widget.description,
        budget: _calculatedPrice,
        scheduledTime: widget.scheduledTime,
        location: finalGeoPoint,
        address: _addressController.text.trim(),
        city: _currentCity.isNotEmpty ? _currentCity : 'Kurnool', // Default to Kurnool if city resolution failed
        requiredSkills: [widget.serviceId],
        images: [],
        assignedTo: widget.craftizenId,
      );

      await _jobService.createJob(newJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Job posted successfully'))));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CitizenHome(initialIndex: 1)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('Failed to post job')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'SetuLink', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Changed title
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const BilingualText(textKey: 'Amount', style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 10),
                            Text('₹${_calculatedPrice.toStringAsFixed(0)}', 
                                 style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_problems.isNotEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: DropdownButtonFormField<QueryDocumentSnapshot>(
                            value: _selectedProblem,
                            items: _problems.map((problem) {
                              final problemData = problem.data() as Map<String, dynamic>;
                              return DropdownMenuItem<QueryDocumentSnapshot>(
                                value: problem,
                                child: Text(problemData['title'] ?? 'N/A'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProblem = value;
                                _calculatePrice();
                              });
                            },
                            decoration: InputDecoration(
                              label: const BilingualText(textKey: 'Service'),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                label: const BilingualText(textKey: 'job_location_address'),
                                hintText: tr('enter_address_hint'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _fetchCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: const BilingualText(textKey: 'get_current_location'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _confirmBooking,
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const BilingualText(textKey: 'confirm_booking'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
