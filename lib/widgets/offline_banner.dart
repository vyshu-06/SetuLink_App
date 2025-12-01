import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({Key? key, required this.child}) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      // Determine offline if result is none
       setState(() {
        // Handle both single result (v5) and list (v6) if upgrading later, but for now strict v5
        // Since the error says 'result' is ConnectivityResult, we treat it as such.
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
     setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            color: Colors.redAccent,
            padding: const EdgeInsets.all(4),
            child: const Text(
              'You are offline. Changes will sync when online.',
              style: TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
