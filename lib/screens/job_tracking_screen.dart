import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random, max, min;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/firebase_options.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/chat_service.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/screens/collect_payment_screen.dart';
import 'package:setulink_app/features/ratings_rewards/presentation/rating_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/widgets/swipe_to_confirm_button.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class JobTrackingScreen extends StatefulWidget {
  final JobModel job;

  const JobTrackingScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends State<JobTrackingScreen> {
  final ChatService _chatService = ChatService();
  final MapController _mapController = MapController();
  
  StreamSubscription? _dbSubscription;
  StreamSubscription? _jobSubscription;
  StreamSubscription? _gpsSubscription;
  
  LatLng? _craftizenPosition;
  List<LatLng> _routePoints = [];
  bool _isCraftizen = false;
  bool _firstLocationReceived = false;
  String? _otherUserName;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    _isCraftizen = widget.job.assignedTo == currentUser?.uid;
    _currentStatus = widget.job.jobStatus;

    _setupTracking();
    _fetchOtherUserName();
    _listenToJobStatus();
  }

  void _listenToJobStatus() {
    _jobSubscription = FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.job.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final status = data['jobStatus'];
        final startOtp = data['startOtp'];
        final endOtp = data['endOtp'];
        
        setState(() {
          _currentStatus = status;
        });

        if (!_isCraftizen) {
          if (status == 'arrived' && startOtp != null && data['startOtpVerified'] != true) {
            _showOtpToCitizen(startOtp, 'Start');
          } else if (status == 'in_progress' && endOtp != null && data['endOtpVerified'] != true) {
            _showOtpToCitizen(endOtp, 'Completion');
          } else if (status == 'completed' || status == 'paid') {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work completed! Redirecting to rating...')));
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatingScreen(
                      jobId: widget.job.id,
                      craftizenId: widget.job.assignedTo!,
                    ),
                  ),
                );
              }
            });
          }
        }
      }
    });
  }

  void _showOtpToCitizen(String otp, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('$type OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide this OTP to the Craftizen to $type the work:'),
            const SizedBox(height: 16),
            Text(otp, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8)),
          ],
        ),
        actions: [],
      ),
    );
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      bool verified = (type == 'Start') ? data['startOtpVerified'] == true : data['endOtpVerified'] == true;
      if (verified) {
        timer.cancel();
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    });
  }

  Future<void> _fetchOtherUserName() async {
    final otherUserId = _isCraftizen ? widget.job.userId : widget.job.assignedTo!;
    final userDoc = await _chatService.getUserDetails(otherUserId);
    if (mounted) {
      setState(() {
        _otherUserName = userDoc['name'] ?? 'User';
      });
    }
  }

  void _setupTracking() async {
    // Sanitize the trip ID for Realtime Database keys
    final tripId = widget.job.id.replaceAll(RegExp(r'[.#$\[\]]'), '_');
    
    // Explicitly use the database URL to ensure connection on all platforms
    String? dbUrl = DefaultFirebaseOptions.currentPlatform.databaseURL;
    
    // Fallback if for some reason the platform options are missing the URL
    if (dbUrl == null || dbUrl.isEmpty) {
      dbUrl = 'https://setulink-app-fb-default-rtdb.asia-southeast1.firebasedatabase.app';
    }

    debugPrint('Tracking Trip ID: $tripId at URL: $dbUrl');
    
    try {
      final DatabaseReference tripRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: dbUrl,
      ).ref("active_trips/$tripId/driver_location");

      // Listen to real-time events from the cloud for BOTH Citizen and Craftizen
      _dbSubscription = tripRef.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map?;
        debugPrint('Received tracking data from RTDB: $data');
        if (data != null && data['latitude'] != null && data['longitude'] != null && mounted) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          
          if (lat.isNaN || lng.isNaN) return;

          final newPos = LatLng(lat, lng);
          
          setState(() {
            _craftizenPosition = newPos;
          });
          _updateRoute();
          _fitMapBounds();
        }
      }, onError: (e) {
        debugPrint('RTDB Listener Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Realtime Sync Error: $e')));
        }
      });

      // For Craftizen, we also ensure they are broadcasting
      if (_isCraftizen) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        // Force an initial update for the trip ref even if global tracking is running
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          _handleNewLocation(position, tripRef);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Firebase Realtime Init Error: $e');
    }
  }

  void _handleNewLocation(Position position, DatabaseReference tripRef) {
    if (position.latitude.isNaN || position.longitude.isNaN) return;

    final newPos = LatLng(position.latitude, position.longitude);
    debugPrint('Craftizen moved to: ${position.latitude}, ${position.longitude}');
    
    if (mounted) {
      setState(() {
        _craftizenPosition = newPos;
      });
      _updateRoute();
    }

    // Broadcast to Realtime Database
    tripRef.set({
      "latitude": position.latitude,
      "longitude": position.longitude,
      "heading": position.heading,
      "timestamp": ServerValue.timestamp,
    }).then((_) {
      debugPrint('Successfully wrote location to RTDB');
    }).catchError((e) {
      debugPrint('Error writing to RTDB: $e');
      // On some platforms, this might fail if the database rules are not set correctly
    });
  }

  void _fitMapBounds() {
    if (_craftizenPosition == null || _firstLocationReceived) return;
    
    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);
    
    // Create bounds that include both points, ensuring no identical points (which might cause NaN in some engines)
    final north = max(housePos.latitude, _craftizenPosition!.latitude);
    final south = min(housePos.latitude, _craftizenPosition!.latitude);
    final east = max(housePos.longitude, _craftizenPosition!.longitude);
    final west = min(housePos.longitude, _craftizenPosition!.longitude);
    
    // Add a tiny offset if points are identical to avoid zero-size bounds
    final finalSouth = south == north ? south - 0.001 : south;
    final finalNorth = south == north ? north + 0.001 : north;
    final finalWest = west == east ? west - 0.001 : west;
    final finalEast = west == east ? east + 0.001 : east;

    final bounds = LatLngBounds(LatLng(finalSouth, finalWest), LatLng(finalNorth, finalEast));
    
    // Use a small delay to ensure the map controller is ready
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(70),
            ),
          );
          _firstLocationReceived = true;
        } catch (e) {
          debugPrint('Error fitting map bounds: $e');
        }
      }
    });
  }

  LatLng? _lastRouteFetchPos;
  Future<void> _updateRoute() async {
    if (_craftizenPosition == null) return;
    
    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);
    
    // Check if positions are too close (within 5 meters) to avoid OSRM zero-length errors
    final distToHouse = _calculateDistance(_craftizenPosition!, housePos);
    if (distToHouse < 5) {
      if (mounted) setState(() => _routePoints = []);
      return;
    }

    // Throttle route fetching: only fetch if moved more than 30 meters from last fetch
    if (_lastRouteFetchPos != null) {
      final movedDist = _calculateDistance(_craftizenPosition!, _lastRouteFetchPos!);
      if (movedDist < 30) return; 
    }

    debugPrint('Fetching new route path from ${_craftizenPosition!.latitude},${_craftizenPosition!.longitude} to ${housePos.latitude},${housePos.longitude}');
    final route = await fetchRoadRoute(_craftizenPosition!, housePos);
    if (mounted && route.isNotEmpty) {
      setState(() {
        _routePoints = route;
        _lastRouteFetchPos = _craftizenPosition;
      });
    }
  }

  Future<List<LatLng>> fetchRoadRoute(LatLng start, LatLng end) async {
    // Correct OSRM endpoint for public use
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          debugPrint('Route fetched with ${coordinates.length} points');
          return coordinates.map((coord) => LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble())).toList();
        }
      } else {
        debugPrint('OSRM Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint("Routing engine connection error: $e");
    }
    return [];
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return const Distance().as(LengthUnit.Meter, p1, p2);
  }

  void _handleArrived() async {
    if (_craftizenPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait for location update...')));
      return;
    }

    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);
    final distance = _calculateDistance(_craftizenPosition!, housePos);

    if (distance > 50) {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Arrival'),
              content: const Text('You are still more than 50 meters away. Have you really reached the exact location?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
              ],
            ),
          ) ?? false;

      if (!confirm) return;
    }

    String startOtp = (1000 + Random().nextInt(9000)).toString();
    await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
      'jobStatus': 'arrived',
      'startOtp': startOtp,
      'startOtpVerified': false,
    });
  }

  void _handleStartWork() async {
    final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).get();
    final correctOtp = doc.data()?['startOtp'];
    String? enteredOtp = await _showOtpInputDialog('Enter Start OTP');
    
    if (enteredOtp == correctOtp) {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
        'jobStatus': 'in_progress',
        'startTime': FieldValue.serverTimestamp(),
        'startOtpVerified': true,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP! Please try again.')));
    }
  }

  void _handleCompleteWork() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: const Text('Are you sure the work is completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    String endOtp = (1000 + Random().nextInt(9000)).toString();
    await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
      'endOtp': endOtp,
      'endOtpVerified': false,
    });

    String? enteredOtp = await _showOtpInputDialog('Enter Completion OTP');
    final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).get();
    final correctOtp = doc.data()?['endOtp'];

    if (enteredOtp == correctOtp) {
      await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
        'jobStatus': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'endOtpVerified': true,
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      final otherUserId = _isCraftizen ? widget.job.userId : widget.job.assignedTo!;
      final chatId = _chatService.getChatId(currentUser!.uid, otherUserId);
      await _chatService.deleteChatMessages(chatId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CollectPaymentScreen(job: widget.job)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP!')));
    }
  }

  Future<String?> _showOtpInputDialog(String title) async {
    String otp = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '4-digit OTP'),
          onChanged: (value) => otp = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, otp), child: const Text('Verify')),
        ],
      ),
    );
  }

  void _openChat() {
    if (_otherUserName == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    final otherUserId = _isCraftizen ? widget.job.userId : widget.job.assignedTo!;
    final chatId = _chatService.getChatId(currentUser!.uid, otherUserId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chatId, otherUserName: _otherUserName!),
      ),
    );
  }

  void _openInExternalMaps() async {
    final lat = widget.job.location.latitude;
    final lng = widget.job.location.longitude;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps application')));
      }
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _jobSubscription?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(textKey: _isCraftizen ? 'Job Tracking' : 'Tracking Craftizen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_craftizenPosition != null) {
                _mapController.move(_craftizenPosition!, 15.0);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: _openInExternalMaps,
          ),
          IconButton(icon: const Icon(Icons.chat), onPressed: _openChat),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: housePos,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.setulink_app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.blue.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // 1. Citizen House (Destination)
                  Marker(
                    point: housePos,
                    width: 50,
                    height: 50,
                    child: const Column(
                      children: [
                        Icon(Icons.home, color: Colors.red, size: 35),
                        Text('Citizen', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
                      ],
                    ),
                  ),
                  // 2. Craftizen (Live Location)
                  if (_craftizenPosition != null)
                    Marker(
                      point: _craftizenPosition!,
                      width: 50,
                      height: 50,
                      child: const Column(
                        children: [
                          Icon(Icons.person_pin_circle, color: Colors.blue, size: 35),
                          Text('Worker', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (!_isCraftizen && _craftizenPosition == null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)],
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Waiting for Craftizen to share live location...',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isCraftizen)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildSliderAction(),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _isCraftizen ? 80 : 0),
        child: FloatingActionButton(
          onPressed: _openChat,
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.message, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSliderAction() {
    String label = '';
    Color color = Colors.green;
    VoidCallback onConfirm = () {};

    if (_currentStatus == 'confirmed' || _currentStatus == 'on_the_way') {
      label = tr('swipe_to_arrive').toUpperCase();
      color = Colors.green;
      onConfirm = _handleArrived;
    } else if (_currentStatus == 'arrived') {
      label = tr('swipe_to_start').toUpperCase();
      color = Colors.blue;
      onConfirm = _handleStartWork;
    } else if (_currentStatus == 'in_progress') {
      label = tr('swipe_to_complete').toUpperCase();
      color = Colors.orange;
      onConfirm = _handleCompleteWork;
    } else {
      return const SizedBox.shrink();
    }

    return SwipeToConfirmButton(
      text: label,
      color: color,
      onConfirm: onConfirm,
    );
  }
}
