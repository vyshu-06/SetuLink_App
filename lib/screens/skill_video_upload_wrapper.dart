import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/skill_video_upload_screen.dart';
import 'package:setulink_app/screens/pending_verification_screen.dart';

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

  void _onVideoUploaded(String skill, String url) {
    _videoUrls[skill] = url;
    _nextStep();
  }

  void _nextStep() {
    if (_currentSkillIndex < widget.passedSkills.length - 1) {
      setState(() {
        _currentSkillIndex++;
      });
    } else {
      // All videos uploaded
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
        appBar: AppBar(
          title: Text(tr('video_upload')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('no_skills_to_verify')),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(tr('back_to_home')),
              ),
            ],
          ),
        ),
      );
    }

    final currentSkill = widget.passedSkills[_currentSkillIndex];

    return SkillVideoUploadScreen(
      userId: widget.userId,
      skill: currentSkill,
      onVideoUploaded: (url) => _onVideoUploaded(currentSkill, url),
    );
  }
}
