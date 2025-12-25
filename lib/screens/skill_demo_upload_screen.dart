import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/pending_verification_screen.dart'; // Import the new screen

class SkillDemoUploadScreen extends StatefulWidget {
  final String userId;

  const SkillDemoUploadScreen({required this.userId, Key? key})
      : super(key: key);

  @override
  State<SkillDemoUploadScreen> createState() => _SkillDemoUploadScreenState();
}

class _SkillDemoUploadScreenState extends State<SkillDemoUploadScreen> {
  File? _videoFile;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleCompletion() async {
    if (_videoFile == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('please_select_video'))));
      return;
    }
    setState(() => _uploading = true);
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('skill_demos')
          .child('${widget.userId}.mp4'); // Use userId for a unique path

      final uploadTask = storageRef.putFile(_videoFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();

      // Save the video URL to the user's document
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'kyc.videoUrl': url,
        'kyc.submittedAt': FieldValue.serverTimestamp(),
        'kycStatus': 'pending',
      });

      // FIX: Navigate to the pending verification screen.
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => PendingVerificationScreen(
            userId: widget.userId,
            commonAnswers: const {},
            passedSkills: const [],
            videoUrls: const {},
          )),
          (route) => false, // Clear all previous routes
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    } finally {
       if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('skill_verification_step', args: ['3','3']))),
       body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             if (_videoFile != null)
              Expanded(
                child: Center(child: Text('${context.tr('video_selected')}:\n${_videoFile!.path.split('/').last}', textAlign: TextAlign.center)),
              )
            else
              Expanded(
                child: Center(child: Text(context.tr('no_video_selected'))),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              onPressed: _pickVideo,
              label: Text(context.tr('record_select_video')),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploading ? null : _handleCompletion,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _uploading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : Text(context.tr('finish')),
            ),
          ],
        ),
      ),
    );
  }
}
