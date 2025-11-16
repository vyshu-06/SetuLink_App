import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class SkillDemoUploadScreen extends StatefulWidget {
  final ValueChanged<String> onUploadComplete;

  const SkillDemoUploadScreen({required this.onUploadComplete, Key? key})
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

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    setState(() => _uploading = true);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('skill_demos')
        .child('${DateTime.now().millisecondsSinceEpoch}.mp4');

    final uploadTask = storageRef.putFile(_videoFile!);
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();

    setState(() => _uploading = false);

    widget.onUploadComplete(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('upload_skill_demo_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_videoFile != null)
              Container(
                height: 200,
                child: Center(child: Text('${context.tr('video_selected')}: ${_videoFile!.path.split('/').last}')),
              )
            else
              Container(
                height: 200,
                child: Center(child: Text(context.tr('no_video_selected'))),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text(context.tr('record_select_video')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploading ? null : _uploadVideo,
              child: _uploading
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) 
                  : Text(context.tr('upload_video')),
            ),
          ],
        ),
      ),
    );
  }
}
