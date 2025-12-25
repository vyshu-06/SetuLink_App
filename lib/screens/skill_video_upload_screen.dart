import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class SkillVideoUploadScreen extends StatefulWidget {
  final String userId;
  final String skill;
  final Function(String url) onVideoUploaded;

  const SkillVideoUploadScreen({
    Key? key,
    required this.userId,
    required this.skill,
    required this.onVideoUploaded,
  }) : super(key: key);

  @override
  State<SkillVideoUploadScreen> createState() => _SkillVideoUploadScreenState();
}

class _SkillVideoUploadScreenState extends State<SkillVideoUploadScreen> {
  File? _videoFile;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );

    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('skill_videos')
          .child(widget.userId)
          .child('${widget.skill}_${DateTime.now().millisecondsSinceEpoch}.mp4');

      final uploadTask = storageRef.putFile(_videoFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      widget.onVideoUploaded(downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
      setState(() {
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr('upload_video_for')} ${widget.skill}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('please_upload_skill_video', args: [widget.skill]),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            if (_videoFile != null) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 8),
              Text(
                tr('video_selected'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Icon(Icons.videocam_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
            ],
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickVideo,
              icon: const Icon(Icons.camera_alt),
              label: Text(tr('record_video')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_videoFile != null && !_uploading) ? _uploadVideo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(tr('upload_and_continue')),
            ),
          ],
        ),
      ),
    );
  }
}
