import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart'; // For hashing OTPs

class JobService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Generate & hash OTP securely
  String _generateOTP() {
    final rand = Random();
    return (rand.nextInt(900000) + 100000).toString();
  }

  String _hashOTP(String otp) {
    return sha256.convert(utf8.encode(otp)).toString();
  }

  // 🔹 Create a new job request
  Future<String?> createJobRequest({
    required String citizenId,
    required String serviceCategory,
    required String serviceId,
    String? craftizenId,
  }) async {
    if (citizenId.isEmpty || serviceCategory.isEmpty || serviceId.isEmpty) {
      throw Exception('Missing required fields');
    }

    try {
      final otpStart = _generateOTP();
      final otpComplete = _generateOTP();

      final jobRef = await _db.collection('jobs').add({
        'citizenId': citizenId,
        'craftizenId': craftizenId,
        'serviceCategory': serviceCategory,
        'serviceId': serviceId,
        'status': JobStatus.requested,
        'otpStartHash': _hashOTP(otpStart),
        'otpCompleteHash': _hashOTP(otpComplete),
        'requestedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'startedAt': null,
        'completedAt': null,
        'ratedAt': null,
        'rating': null,
        'feedback': null,
      });

      // Optionally return OTPs for user confirmation screen
      return jobRef.id;
    } catch (e) {
      print('Error creating job: $e');
      return null;
    }
  }

  // 🔹 Accept job (with transaction)
  Future<bool> acceptJob(String jobId, String craftizenId) async {
    try {
      await _db.runTransaction((txn) async {
        final jobRef = _db.collection('jobs').doc(jobId);
        final snapshot = await txn.get(jobRef);

        if (!snapshot.exists) throw Exception('Job not found');
        if (snapshot['status'] != JobStatus.requested) {
          throw Exception('Job already accepted');
        }

        txn.update(jobRef, {
          'craftizenId': craftizenId,
          'status': JobStatus.accepted,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      print('Accept job error: $e');
      return false;
    }
  }

  // 🔹 Confirm job start
  Future<bool> confirmJobStart(String jobId, String otp) async {
    try {
      final jobRef = _db.collection('jobs').doc(jobId);
      final doc = await jobRef.get();

      if (!doc.exists) return false;
      final data = doc.data()!;
      final hash = _hashOTP(otp);

      if (data['otpStartHash'] == hash && data['status'] == JobStatus.accepted) {
        await jobRef.update({
          'status': JobStatus.started,
          'startedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Confirm job start error: $e');
      return false;
    }
  }

  // 🔹 Confirm job completion
  Future<bool> confirmJobCompletion(
      String jobId,
      String otp,
      int rating,
      String feedback,
      ) async {
    try {
      final jobRef = _db.collection('jobs').doc(jobId);
      final doc = await jobRef.get();

      if (!doc.exists) return false;
      final data = doc.data()!;
      final hash = _hashOTP(otp);

      if (data['otpCompleteHash'] == hash && data['status'] == JobStatus.started) {
        await jobRef.update({
          'status': JobStatus.completed,
          'completedAt': FieldValue.serverTimestamp(),
          'rating': rating,
          'feedback': feedback,
          'ratedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Confirm job completion error: $e');
      return false;
    }
  }
}

// 🔹 Enum-like status constants
class JobStatus {
  static const requested = 'requested';
  static const accepted = 'accepted';
  static const started = 'started';
  static const completed = 'completed';
}
