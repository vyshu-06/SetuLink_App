import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:setulink_app/screens/pending_verification_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';

class SkillVideoUploadWrapper extends StatefulWidget {
  final String userId;
  final List<String> passedSkills;
  final Map<String, String> commonAnswers;

  const SkillVideoUploadWrapper({
    Key? key,
    required this.userId,
    required this.passedSkills,
    required this.commonAnswers,
  }) : super(key: key);

  @override
  State<SkillVideoUploadWrapper> createState() =>
      _SkillVideoUploadWrapperState();
}

class _SkillVideoUploadWrapperState extends State<SkillVideoUploadWrapper> {
  int _currentSkillIndex = 0;
  final Map<String, String> _videoUrls = {};
  bool _isUploading = false;

  // --- TELEGRAM CONFIGURATION ---
  final String botToken = "8549367905:AAG86dDVZ3W9uJYCxdvZNUlUYCHrNg9X7C8";
  final String chatId = "-1003629646389"; // e.g. "-100123456789"

  Future<void> _pickAndUploadVideo(String skill) async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await video.readAsBytes();

      // Sending to Telegram via MultiPart Request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.telegram.org/bot$botToken/sendVideo'),
      );

      request.fields['chat_id'] = chatId;
      request.fields['caption'] = "User ID: ${widget.userId}\nSkill: $skill\nVerified via SetuLink";

      request.files.add(http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: "${skill}_verification.mp4",
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Success: We store a placeholder URL in Firestore
        // since the video is safely in your Telegram channel
        _videoUrls[skill] = "stored_on_telegram";
        _nextStep();
      } else {
        throw Exception("Telegram Error: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _nextStep() {
    if (_currentSkillIndex < widget.passedSkills.length - 1) {
      setState(() {
        _currentSkillIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingVerificationScreen(
            userId: widget.userId,
            commonAnswers: widget.commonAnswers,
            passedSkills: widget.passedSkills,
            videoUrls: _videoUrls,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.passedSkills.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('video_upload'))),
        body: Center(child: Text(tr('no_skills_to_verify'))),
      );
    }

    final currentSkill = widget.passedSkills[_currentSkillIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Skill Verification"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 100, color: AppColors.primaryColor),
            const SizedBox(height: 24),
            Text(
              "Upload a video for ${currentSkill.replaceAll('_', ' ').toUpperCase()}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text("Skill ${_currentSkillIndex + 1} of ${widget.passedSkills.length}"),
            const SizedBox(height: 40),
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Sending video to secure servers..."),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadVideo(currentSkill),
                icon: const Icon(Icons.video_call),
                label: const Text("Select Video & Continue"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
