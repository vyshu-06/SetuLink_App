import 'dart:io';
import 'dart:async';
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

class _SkillVideoUploadScreenState extends State<SkillVideoUploadScreen> 
    with SingleTickerProviderStateMixin {
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
    try {
      final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30), 
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        final fileSize = await pickedFile.length();
        if (fileSize > 50 * 1024 * 1024) { 
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video too large. Max 50MB. Please choose shorter video.')),
            );
          }
          return;
        }
        
        setState(() {
          _videoFile = pickedFile;
          _uploadProgress = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
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
          .child('skill_videos/${widget.userId}/${widget.skill}_${DateTime.now().millisecondsSinceEpoch}.mp4');

      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await _videoFile!.readAsBytes();
        final metadata = SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {'userId': widget.userId, 'skill': widget.skill},
        );
        
        uploadTask = storageRef.putData(bytes, metadata);
      } else {
        uploadTask = storageRef.putFile(
          File(_videoFile!.path),
          SettableMetadata(
            contentType: 'video/mp4',
            customMetadata: {'userId': widget.userId, 'skill': widget.skill},
          ),
        );
      }

      final completer = Completer<String>();
      
      final subscription = uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            if (snapshot.totalBytes > 0) {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            }
          });
        }
        
        if (snapshot.state == TaskState.success) {
          snapshot.ref.getDownloadURL().then((url) {
            if (!completer.isCompleted) completer.complete(url);
          });
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      });

      // TIMEOUT after 2 minutes
      Timer(const Duration(minutes: 2), () {
        if (!completer.isCompleted && mounted) {
          uploadTask.cancel();
          completer.completeError(TimeoutException('Upload timeout', const Duration(minutes: 2)));
        }
      });

      final downloadUrl = await completer.future;
      subscription.cancel();

      widget.onVideoUploaded(downloadUrl);
      
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        setState(() => _uploading = false);
        String errorMsg = e is TimeoutException 
            ? 'Upload timeout. Try shorter video or better connection.' 
            : 'Upload failed: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _uploadVideo,
            ),
          ),
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
          '${tr('upload_video_for')} ${widget.skill}',
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
                      tr('please_upload_skill_video', namedArgs: {'skill': widget.skill}),
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
                          : 'Uploading...',
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
