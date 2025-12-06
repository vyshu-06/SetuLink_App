import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Map<String, dynamic>? _currentUserData;

  // Get current user data (if logged in)
  Map<String, dynamic>? getCurrentUser() {
    return _currentUserData;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateReferralCode(String name) {
    final random = Random();
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = cleanName.length >= 4 ? cleanName.substring(0, 4) : cleanName.padRight(4, 'X');
    final suffix = (1000 + random.nextInt(9000)).toString();
    return '$prefix$suffix';
  }

  // Register user with email/password
  Future<Map<String, dynamic>?> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
    String role, {
    String? referralCode,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        final myReferralCode = _generateReferralCode(name);
        
        final userData = {
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'role': role,
          'referralCode': myReferralCode,
          'referredBy': referralCode, // Store who referred this user
          'referralCount': 0,
          'loyaltyPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'skills': role == 'craftizen' ? [] : null,
          'kyc': {'verified': false},
        };

        try {
            await _db.collection('users').doc(user.uid).set(userData);
            _currentUserData = userData;
            
            // Save FCM token
            try {
                final token = await _fcm.getToken();
                if (token != null) {
                    await _db.collection('users').doc(user.uid).update({'fcmToken': token});
                }
            } catch (fcmError) {
                debugPrint('FCM Token Error (Ignored for Web): $fcmError');
            }

            return userData;
        } catch (dbError) {
             debugPrint('Firestore Write Error: $dbError');
             // If writing to DB fails, delete the Auth user so they aren't stuck in limbo
             await user.delete(); 
             return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Register error: $e');
      return null;
    }
  }

  // SignIn user with email/password
  Future<Map<String, dynamic>?> signInWithEmail(String email, String password, String role) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          throw FirebaseAuthException(code: 'user-doc-missing', message: 'User profile data missing.');
        }
        
        if (userDoc.data()?['role'] != role) {
           throw FirebaseAuthException(code: 'wrong-role', message: 'Account exists but role does not match.');
        }

        _currentUserData = userDoc.data();

        // Save FCM token
        try {
            final token = await _fcm.getToken();
            if (token != null) {
              await _db.collection('users').doc(user.uid).update({'fcmToken': token});
            }
        } catch (e) {
            debugPrint("FCM Token error: $e");
        }

        return _currentUserData;
      }
      return null; 
    } catch (e) {
      print('SignIn error: $e');
      rethrow;
    }
  }

  // Send OTP for phone number verification
  Future<void> sendOtp(String phoneNumber, {
    required Function(String, int?) codeSent,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Verify OTP and sign in user by phone
  Future<void> verifyOtp(String verificationId, String smsCode, String role) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await signInWithCredential(credential, role);
  }

  // Sign in with any credential
  Future<void> signInWithCredential(AuthCredential credential, String role) async {
    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      final userDoc = await _db.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        _currentUserData = userDoc.data();
      } else {
        // Create new user document if signing in for the first time with phone
        final myReferralCode = _generateReferralCode('User'); // Generic name for phone auth
        final userData = {
          'uid': userCredential.user!.uid,
          'phone': userCredential.user!.phoneNumber,
          'role': role,
          'referralCode': myReferralCode,
          'referralCount': 0,
          'loyaltyPoints': 0,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _db.collection('users').doc(userCredential.user!.uid).set(userData);
        _currentUserData = userData;
      }

      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(userCredential.user!.uid).update({'fcmToken': token});
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserData = null;
  }
}
