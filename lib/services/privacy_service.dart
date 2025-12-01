import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // For sharing the exported file
// Note: You need to add share_plus to pubspec.yaml if not present, or I can use a simpler mock for now.
// I will use a basic file write and print path if share_plus is missing, but the prompt asks for "File download or email delivery".
// I'll implement the logic to generate the string and rely on UI to handle the "download" action or just return the string.

class PrivacyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Consent Management
  Future<void> updateConsent(String userId, {required bool granted, String version = "v1.0"}) async {
    await _db.collection('users').doc(userId).update({
      'consent': {
        'granted': granted,
        'grantedAt': granted ? FieldValue.serverTimestamp() : null,
        'withdrawnAt': granted ? null : FieldValue.serverTimestamp(),
        'version': version,
      }
    });
  }

  // 2. Data Export
  Future<String> exportUserData(String userId) async {
    try {
      // Fetch User Profile
      final userDoc = await _db.collection('users').doc(userId).get();
      
      // Fetch Jobs (Raised by user or assigned to user)
      // Note: Indexes might be required for these queries
      final jobsRaisedSnap = await _db.collection('jobs').where('userId', isEqualTo: userId).get();
      final jobsAssignedSnap = await _db.collection('jobs').where('assignedTo', isEqualTo: userId).get();
      
      // Fetch Disputes
      final disputesSnap = await _db.collection('disputes').where('raisedBy', isEqualTo: userId).get();
      
      // Aggregate
      Map<String, dynamic> exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'userProfile': userDoc.data(),
        'jobs_requested': jobsRaisedSnap.docs.map((d) => d.data()).toList(),
        'jobs_assigned': jobsAssignedSnap.docs.map((d) => d.data()).toList(),
        'disputes': disputesSnap.docs.map((d) => d.data()).toList(),
        // Add other collections as needed (e.g., reviews, chats)
      };

      return jsonEncode(exportData);
    } catch (e) {
      print("Error exporting data: $e");
      rethrow;
    }
  }

  // 3. Request Deletion
  Future<void> requestUserDeletion(String userId) async {
    await _db.collection('users').doc(userId).update({
      'dataRequests': FieldValue.arrayUnion([{
        'type': 'deletion',
        'status': 'pending',
        'requestedAt': Timestamp.now(), // Use Timestamp for consistency in array
      }]),
      'consent.withdrawnAt': FieldValue.serverTimestamp(),
      'accountStatus': 'deletion_requested', // Flag for app logic
    });
    
    // In a real system, a Cloud Function would pick this up to perform the actual deletion after a grace period.
  }

  // Helper to save string to file
  Future<File> saveExportToFile(String data, String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/user_data_export_${userId}_${DateTime.now().millisecondsSinceEpoch}.json');
    return await file.writeAsString(data);
  }
}
