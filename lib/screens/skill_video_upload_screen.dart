import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/theme/app_colors.dart';

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

class _SkillVideoUploadScreenState extends State<SkillVideoUploadScreen> with SingleTickerProviderStateMixin {
  XFile? _videoFile;
  bool _uploading = false;
  double _uploadProgress = 0;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final XFile? pickedFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 2),
    );

    if (pickedFile != null) {
      setState(() {
        _videoFile = pickedFile;
        _uploadProgress = 0;
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('skill_videos')
          .child(widget.userId)
          .child('${widget.skill}_${DateTime.now().millisecondsSinceEpoch}.mp4');

      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Correct way for Web to avoid memory hang: use readAsBytes directly in putData
        uploadTask = storageRef.putData(
          await _videoFile!.readAsBytes(),
          SettableMetadata(contentType: 'video/mp4'),
        );
      } else {
        uploadTask = storageRef.putFile(
          File(_videoFile!.path),
          SettableMetadata(contentType: 'video/mp4'),
        );
      }

      // Listen to progress events
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          if (mounted && snapshot.totalBytes > 0) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          }
        },
        onError: (e) {
          debugPrint('Upload error: $e');
          if (mounted) {
            setState(() => _uploading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload error: $e')),
            );
          }
        },
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      widget.onVideoUploaded(downloadUrl);
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          tr('upload_video_for', namedArgs: {'skill': tr(widget.skill)}),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    Text(
                      tr('please_upload_skill_video', namedArgs: {'skill': tr(widget.skill)}),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _videoFile != null
                        ? const Icon(Icons.check_circle, color: Colors.white, size: 80)
                        : const Icon(Icons.videocam_outlined, size: 80, color: Colors.white70),
                    const SizedBox(height: 16),
                    if (_videoFile != null)
                      Text(
                        tr('video_selected'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 30),
                    if (_uploading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _uploadProgress > 0 
                          ? '${(_uploadProgress * 100).toStringAsFixed(0)}%'
                          : tr('uploading'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.video_call),
                        label: Text(tr(kIsWeb ? 'select_video' : 'record_video')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _videoFile != null ? _uploadVideo : null,
                        child: Text(tr('upload_and_continue')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
