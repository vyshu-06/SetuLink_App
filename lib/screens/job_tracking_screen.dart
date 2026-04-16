import 'dart:async';
import 'dart:math' show cos, sqrt, asin, Random;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:setulink_app/models/job_model.dart';
import 'package:setulink_app/services/location_service.dart';
import 'package:setulink_app/services/chat_service.dart';
import 'package:setulink_app/screens/chat_screen.dart';
import 'package:setulink_app/screens/collect_payment_screen.dart';
import 'package:setulink_app/features/ratings_rewards/presentation/rating_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class JobTrackingScreen extends StatefulWidget {
  final JobModel job;

  const JobTrackingScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobTrackingScreen> createState() => _JobTrackingScreenState();
}

class _JobTrackingScreenState extends State<JobTrackingScreen> {
  final LocationService _locationService = LocationService();
  final ChatService _chatService = ChatService();
  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription? _locationSubscription;
  StreamSubscription? _jobSubscription;
  LatLng? _craftizenPosition;
  Set<Marker> _markers = {};
  bool _isCraftizen = false;
  String? _otherUserName;
  double _sliderValue = 0.0;
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
          } else if (status == 'completed') {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: BilingualText(textKey: 'Work completed! Redirecting...')));
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
        actions: [
          // The dialog will close automatically via status listener when OTP is verified
        ],
      ),
    );
    // Auto-close dialog logic when OTP is verified in Firestore
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).get();
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

  void _setupTracking() {
    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);
    _markers.add(
      Marker(
        markerId: const MarkerId('citizen_house'),
        position: housePos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Citizen House'),
      ),
    );

    if (_isCraftizen) {
      _locationSubscription = Stream.periodic(const Duration(seconds: 10)).listen((_) async {
        await _locationService.updateUserLocation(widget.job.assignedTo!);
      });
      _locationService.updateUserLocation(widget.job.assignedTo!);
    }

    _locationService.getUserLocationStream(widget.job.assignedTo!).listen((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['position'] != null) {
        final GeoPoint geoPoint = data['position']['geopoint'];
        if (mounted) {
          setState(() {
            _craftizenPosition = LatLng(geoPoint.latitude, geoPoint.longitude);
            _updateCraftizenMarker(_craftizenPosition!);
          });
        }
      }
    });
  }

  void _updateCraftizenMarker(LatLng pos) {
    _markers.removeWhere((m) => m.markerId.value == 'craftizen');
    _markers.add(
      Marker(
        markerId: const MarkerId('craftizen'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Craftizen'),
      ),
    );
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; 
  }

  void _handleArrived() async {
    if (_craftizenPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait for location update...')));
      setState(() => _sliderValue = 0.0);
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

      if (!confirm) {
        setState(() => _sliderValue = 0.0);
        return;
      }
    }

    // Generate Start OTP when arrived
    String startOtp = (1000 + Random().nextInt(9000)).toString();
    await FirebaseFirestore.instance.collection('jobs').doc(widget.job.id).update({
      'jobStatus': 'arrived',
      'startOtp': startOtp,
      'startOtpVerified': false,
    });

    setState(() {
      _sliderValue = 0.0;
      _currentStatus = 'arrived';
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
      setState(() {
        _sliderValue = 0.0;
        _currentStatus = 'in_progress';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP! Please try again.')));
      setState(() => _sliderValue = 0.0);
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

    if (!confirm) {
      setState(() => _sliderValue = 0.0);
      return;
    }

    // Generate End OTP
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CollectPaymentScreen(job: widget.job)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP!')));
      setState(() => _sliderValue = 0.0);
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

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _jobSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final housePos = LatLng(widget.job.location.latitude, widget.job.location.longitude);

    return Scaffold(
      appBar: AppBar(
        title: BilingualText(textKey: _isCraftizen ? 'Job Tracking' : 'Tracking Craftizen'),
        actions: [IconButton(icon: const Icon(Icons.chat), onPressed: _openChat)],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: housePos, zoom: 14.0),
            onMapCreated: (controller) => _controller.complete(controller),
            markers: _markers,
            myLocationEnabled: true,
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
    Function(double) onChanged = (val) {};

    if (_currentStatus == 'confirmed' || _currentStatus == 'on_the_way') {
      label = 'ARRIVED';
      color = Colors.green;
      onChanged = (value) {
        setState(() => _sliderValue = value);
        if (value == 1.0) _handleArrived();
      };
    } else if (_currentStatus == 'arrived') {
      label = 'START THE WORK';
      color = Colors.blue;
      onChanged = (value) {
        setState(() => _sliderValue = value);
        if (value == 1.0) _handleStartWork();
      };
    } else if (_currentStatus == 'in_progress') {
      label = 'WORK COMPLETED';
      color = Colors.orange;
      onChanged = (value) {
        setState(() => _sliderValue = value);
        if (value == 1.0) _handleCompleteWork();
      };
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.swipe, color: color),
          Expanded(
            child: Slider(
              value: _sliderValue,
              activeColor: color,
              inactiveColor: color.withOpacity(0.3),
              onChanged: onChanged,
            ),
          ),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
