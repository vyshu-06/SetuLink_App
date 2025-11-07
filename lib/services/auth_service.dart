import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hash password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Register user with email/password, name, phone, role
  Future<Map<String, dynamic>?> registerWithEmail(
      String email,
      String password,
      String name,
      String phone,
      String role,
      ) async {
    try {
      final hashedPwd = _hashPassword(password);
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Save extra user info to Firestore
      final userData = {
        'uid': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'hashedPassword': hashedPwd, // Storing for reference, though Firebase handles auth
      };

      // Add skills field for craftizens
      if (role == 'craftizen') {
        userData['skills'] = [];
        userData['verified'] = false;
      }

      await _db.collection('users').doc(userId).set(userData);

      return userData;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // SignIn user with email/password
  Future<Map<String, dynamic>?> signInWithEmail(
      String email,
      String password,
      String role
      ) async {
    try {
      // First verify the user exists with this role
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user found with this email and role');
        return null;
      }

      // Firebase Auth sign-in with email/password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return user data from Firestore
      final userDoc = userQuery.docs.first;
      return userDoc.data();
    } catch (e) {
      print('SignIn error: $e');
      return null;
    }
  }

  // Send OTP for phone number verification
  Future<String?> sendOTP(
      String phoneNumber, {
        required Function(String verificationId) onCodeSent,
      }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-signin can be handled here
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone auth failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout if needed
        },
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      print('sendOTP error: $e');
      return e.toString();
    }
  }

  // Verify OTP and sign in user by phone
  Future<Map<String, dynamic>?> verifyOTP(
      String verificationId,
      String smsCode,
      String role
      ) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final userId = userCredential.user!.uid;

      // Check if user exists with this UID and role in Firestore
      final userDoc = await _db.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()?['role'] == role) {
        return userDoc.data();
      }

      return null;
    } catch (e) {
      print('verifyOTP error: $e');
      return null;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }