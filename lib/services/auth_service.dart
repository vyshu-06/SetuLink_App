import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService() {
    initializeMockUsers();
  }

  // Mock user storage (replace with actual database later)
  static final List<Map<String, dynamic>> _mockUsers = [];

  // Mock current user
  static Map<String, dynamic>? _currentUser;

  // Simple password hashing (without crypto package)
  String _hashPassword(String password) {
    // Simple base64 encoding instead of SHA-256
    final bytes = utf8.encode(password);
    return base64.encode(bytes);
  }

  // Register user with email/password, name, phone, role
  Future<Map<String, dynamic>?> registerWithEmail(String email,
      String password,
      String name,
      String phone,
      String role,) async {
    try {
      final hashedPwd = _hashPassword(password);

      // Check if user already exists
      if (_mockUsers.any((user) => user['email'] == email)) {
        print('User already exists with this email');
        return null;
      }

      // Create user data
      final userId = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final userData = <String, dynamic>{
        'uid': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'role': role,
        'createdAt': DateTime.now().toString(),
        'hashedPassword': hashedPwd,
      };

      // Add skills field for craftizens
      if (role == 'craftizen') {
        userData['skills'] = <String>[];
        userData['verified'] = false;
      }

      // Save to mock storage
      _mockUsers.add(userData);

      // Set as current user
      _currentUser = userData;

      print('User registered successfully: $email');
      return userData;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // SignIn user with email/password
  Future<Map<String, dynamic>?> signInWithEmail(String email,
      String password,
      String role,) async {
    try {
      // Find user with matching email and role
      final hashedPwd = _hashPassword(password);
      final user = _mockUsers.firstWhere(
            (user) =>
        user['email'] == email &&
            user['role'] == role &&
            user['hashedPassword'] == hashedPwd,
        orElse: () => <String, dynamic>{},
      );

      if (user.isEmpty) {
        print('No user found with this email, role, and password');
        return null;
      }

      // Set as current user
      _currentUser = user;

      print('User signed in successfully: $email');
      return user;
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
      // By default, we'll just create a mock user object here
      _currentUser = {
        'uid': userCredential.user!.uid,
        'phone': userCredential.user!.phoneNumber,
        'role': role,
      };
    }
  }

  // Get current user
  Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    print('User signed out');
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final user = _mockUsers.firstWhere(
            (user) => user['uid'] == uid,
        orElse: () => <String, dynamic>{},
      );
      return user.isEmpty ? null : user;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Add some mock users for testing
  void initializeMockUsers() {
    if (_mockUsers.isEmpty) {
      _mockUsers.addAll([
        <String, dynamic>{
          'uid': '1',
          'email': 'citizen@example.com',
          'name': 'John Citizen',
          'phone': '+1234567890',
          'role': 'citizen',
          'createdAt': DateTime.now().toString(),
          'hashedPassword': _hashPassword('password123'),
        },
        <String, dynamic>{
          'uid': '2',
          'email': 'craftizen@example.com',
          'name': 'Jane Craftizen',
          'phone': '+0987654321',
          'role': 'craftizen',
          'skills': <String>['Plumbing', 'Electrical'],
          'verified': true,
          'createdAt': DateTime.now().toString(),
          'hashedPassword': _hashPassword('password123'),
        },
      ]);
    }
  }
}
