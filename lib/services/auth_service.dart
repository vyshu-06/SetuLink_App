import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  // Register user with email/password
  Future<Map<String, dynamic>?> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
    String role,
  ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        final userData = {
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'skills': role == 'craftizen' ? [] : null,
          'kyc': {'verified': false},
        };

        await _db.collection('users').doc(user.uid).set(userData);
        _currentUserData = userData;

        // Save FCM token
        final token = await _fcm.getToken();
        await _db.collection('users').doc(user.uid).update({'fcmToken': token});

        return userData;
      }
      return null;
    } catch (e) {
      print('Register error: $e');
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
        if (userDoc.exists && userDoc.data()?['role'] == role) {
          _currentUserData = userDoc.data();

          // Save FCM token
          final token = await _fcm.getToken();
          await _db.collection('users').doc(user.uid).update({'fcmToken': token});

          return _currentUserData;
        }
      }
      return null; // Return null if role does not match or user does not exist
    } catch (e) {
      print('SignIn error: $e');
      return null;
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
        final userData = {
          'uid': userCredential.user!.uid,
          'phone': userCredential.user!.phoneNumber,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await _db.collection('users').doc(userCredential.user!.uid).set(userData);
        _currentUserData = userData;
      }

      final token = await _fcm.getToken();
      await _db.collection('users').doc(userCredential.user!.uid).update({'fcmToken': token});
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUserData = null;
  }
}
