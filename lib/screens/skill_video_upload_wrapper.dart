import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:setulink_app/screens/pending_verification_screen.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

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
        appBar: AppBar(title: const BilingualText(textKey: 'upload_skill_demo_title')),
        body: const Center(child: BilingualText(textKey: 'no_skills_added')),
      );
    }

    final currentSkill = widget.passedSkills[_currentSkillIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const BilingualText(textKey: 'skill_verification_title'),
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
            BilingualText(
              textKey: 'upload_video_for',
              args: [currentSkill.replaceAll('_', ' ').toUpperCase()],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            BilingualText(
              textKey: 'question_progress',
              args: [(_currentSkillIndex + 1).toString(), widget.passedSkills.length.toString()],
            ),
            const SizedBox(height: 40),
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  BilingualText(textKey: 'upload_video'), // Using upload_video as placeholder for "Sending..."
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => _pickAndUploadVideo(currentSkill),
                icon: const Icon(Icons.video_call),
                label: const BilingualText(textKey: 'upload_and_continue'),
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
