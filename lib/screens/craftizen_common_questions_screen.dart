import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/skill_quiz_screen.dart';

class CraftizenCommonQuestionsScreen extends StatefulWidget {
  final String userId;
  final List<String> selectedSkills;

  const CraftizenCommonQuestionsScreen(
      {Key? key, required this.userId, required this.selectedSkills})
      : super(key: key);

  @override
  State<CraftizenCommonQuestionsScreen> createState() =>
      _CraftizenCommonQuestionsScreenState();
}

class _CraftizenCommonQuestionsScreenState
    extends State<CraftizenCommonQuestionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _answers = {};
  bool _isLoading = false;

  // The 3 common questions with multiple choice options
  final List<Map<String, dynamic>> _questions = [
    {
      'key': 'question_1',
      'textKey': 'are_you_willing_to_undergo_background_verification',
      'options': ['yes', 'no']
    },
    {
      'key': 'question_2',
      'textKey': 'do_you_have_your_own_tools_and_equipment',
      'options': ['yes', 'no']
    },
    {
      'key': 'question_3',
      'textKey': 'are_you_available_to_work_on_weekends',
      'options': ['yes', 'no']
    },
  ];

  Future<void> _submitAnswers() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if all questions are answered
      if (_answers.length != _questions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('please_answer_all_questions'))),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      try {
        // Save answers to Firestore
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'kyc.commonAnswers': _answers,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SkillQuizScreen(
                userId: widget.userId,
                selectedSkills: widget.selectedSkills,
                commonAnswers: _answers,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tr('error_saving_answers')}: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('common_questions')),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                tr('please_answer_these_common_questions'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ..._questions.map((question) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(question['textKey']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...question['options'].map<Widget>((option) {
                      return RadioListTile<String>(
                        title: Text(tr(option)),
                        value: option,
                        groupValue: _answers[question['key']],
                        onChanged: (value) {
                          setState(() {
                            _answers[question['key']] = value!;
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitAnswers,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(tr('next')),
            ),
          ],
        ),
      ),
    );
  }
}
