import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  User? get currentUser => _auth.currentUser;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) await _saveDeviceToken(cred.user!.uid);
      return cred.user;
    } catch (e) { return null; }
  }

  Future<User?> registerWithEmail(String email, String password, String name, String phone, String role, {String? referralCode}) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          if (referralCode != null) 'referredBy': referralCode,
        });
        await _saveDeviceToken(user.uid);
      }
      return user;
    } catch (e) {
      print("Registration error: $e");
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendOtp(String phoneNumber, { 
    required Function(PhoneAuthCredential) verificationCompleted, 
    required Function(FirebaseAuthException) verificationFailed, 
    required Function(String, int?) codeSent, 
    required Function(String) codeAutoRetrievalTimeout
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<User?> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      return await signInWithCredential(credential);
    } catch (e) {
      return null;
    }
  }

  Future<User?> signInWithCredential(AuthCredential credential) async {
    try {
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) await _saveDeviceToken(cred.user!.uid);
      return cred.user;
    } catch (e) { return null; }
  }

  Future<void> _saveDeviceToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({'fcmToken': token});
      }
    } catch (e) { /* Fail silently */ }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims?['admin'] == true;
  }

  String hashPassword(String password) {
    // This is a placeholder for a real hashing function.
    // In a real app, you would use a library like crypto.
    return password;
  }
}
