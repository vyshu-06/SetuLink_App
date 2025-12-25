import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/screens/skill_video_upload_wrapper.dart';

class SkillQuizScreen extends StatefulWidget {
  final String userId;
  final List<String> selectedSkills;
  final Map<String, String>? commonAnswers;

  const SkillQuizScreen({
    Key? key,
    required this.userId,
    required this.selectedSkills,
    this.commonAnswers,
  }) : super(key: key);

  @override
  State<SkillQuizScreen> createState() => _SkillQuizScreenState();
}

class _SkillQuizScreenState extends State<SkillQuizScreen> {
  int _currentSkillIndex = 0;
  int _currentQuestionIndex = 0;
  int _score = 0;
  final List<String> _passedSkills = [];
  String _selectedLanguage = 'English';

  // Questions Database
  final Map<String, List<Map<String, dynamic>>> _allQuestions = {
    'plumber': [
      {'q': 'plumber_q1', 'options': ['plumber_q1_op1', 'plumber_q1_op2', 'plumber_q1_op3', 'plumber_q1_op4'], 'a': 1},
      {'q': 'plumber_q2', 'options': ['plumber_q2_op1', 'plumber_q2_op2', 'plumber_q2_op3', 'plumber_q2_op4'], 'a': 1},
      {'q': 'plumber_q3', 'options': ['plumber_q3_op1', 'plumber_q3_op2', 'plumber_q3_op3', 'plumber_q3_op4'], 'a': 1},
      {'q': 'plumber_q4', 'options': ['plumber_q4_op1', 'plumber_q4_op2', 'plumber_q4_op3', 'plumber_q4_op4'], 'a': 1},
      {'q': 'plumber_q5', 'options': ['plumber_q5_op1', 'plumber_q5_op2', 'plumber_q5_op3', 'plumber_q5_op4'], 'a': 0},
      {'q': 'plumber_q6', 'options': ['plumber_q6_op1', 'plumber_q6_op2', 'plumber_q6_op3', 'plumber_q6_op4'], 'a': 1},
      {'q': 'plumber_q7', 'options': ['plumber_q7_op1', 'plumber_q7_op2', 'plumber_q7_op3', 'plumber_q7_op4'], 'a': 0},
      {'q': 'plumber_q8', 'options': ['plumber_q8_op1', 'plumber_q8_op2', 'plumber_q8_op3', 'plumber_q8_op4'], 'a': 1},
      {'q': 'plumber_q9', 'options': ['plumber_q9_op1', 'plumber_q9_op2', 'plumber_q9_op3', 'plumber_q9_op4'], 'a': 1},
      {'q': 'plumber_q10', 'options': ['plumber_q10_op1', 'plumber_q10_op2', 'plumber_q10_op3', 'plumber_q10_op4'], 'a': 1},
    ],
    'electrician': [
      {'q': 'electrician_q1', 'options': ['electrician_q1_op1', 'electrician_q1_op2', 'electrician_q1_op3', 'electrician_q1_op4'], 'a': 1},
      {'q': 'electrician_q2', 'options': ['electrician_q2_op1', 'electrician_q2_op2', 'electrician_q2_op3', 'electrician_q2_op4'], 'a': 2},
      {'q': 'electrician_q3', 'options': ['electrician_q3_op1', 'electrician_q3_op2', 'electrician_q3_op3', 'electrician_q3_op4'], 'a': 1},
      {'q': 'electrician_q4', 'options': ['electrician_q4_op1', 'electrician_q4_op2', 'electrician_q4_op3', 'electrician_q4_op4'], 'a': 1},
      {'q': 'electrician_q5', 'options': ['electrician_q5_op1', 'electrician_q5_op2', 'electrician_q5_op3', 'electrician_q5_op4'], 'a': 0},
      {'q': 'electrician_q6', 'options': ['electrician_q6_op1', 'electrician_q6_op2', 'electrician_q6_op3', 'electrician_q6_op4'], 'a': 1},
      {'q': 'electrician_q7', 'options': ['electrician_q7_op1', 'electrician_q7_op2', 'electrician_q7_op3', 'electrician_q7_op4'], 'a': 1},
      {'q': 'electrician_q8', 'options': ['electrician_q8_op1', 'electrician_q8_op2', 'electrician_q8_op3', 'electrician_q8_op4'], 'a': 2},
      {'q': 'electrician_q9', 'options': ['electrician_q9_op1', 'electrician_q9_op2', 'electrician_q9_op3', 'electrician_q9_op4'], 'a': 1},
      {'q': 'electrician_q10', 'options': ['electrician_q10_op1', 'electrician_q10_op2', 'electrician_q10_op3', 'electrician_q10_op4'], 'a': 1},
    ],
    'carpenter': [
      {'q': 'carpenter_q1', 'options': ['carpenter_q1_op1', 'carpenter_q1_op2', 'carpenter_q1_op3', 'carpenter_q1_op4'], 'a': 1},
      {'q': 'carpenter_q2', 'options': ['carpenter_q2_op1', 'carpenter_q2_op2', 'carpenter_q2_op3', 'carpenter_q2_op4'], 'a': 1},
      {'q': 'carpenter_q3', 'options': ['carpenter_q3_op1', 'carpenter_q3_op2', 'carpenter_q3_op3', 'carpenter_q3_op4'], 'a': 0},
      {'q': 'carpenter_q4', 'options': ['carpenter_q4_op1', 'carpenter_q4_op2', 'carpenter_q4_op3', 'carpenter_q4_op4'], 'a': 1},
      {'q': 'carpenter_q5', 'options': ['carpenter_q5_op1', 'carpenter_q5_op2', 'carpenter_q5_op3', 'carpenter_q5_op4'], 'a': 1},
      {'q': 'carpenter_q6', 'options': ['carpenter_q6_op1', 'carpenter_q6_op2', 'carpenter_q6_op3', 'carpenter_q6_op4'], 'a': 1},
      {'q': 'carpenter_q7', 'options': ['carpenter_q7_op1', 'carpenter_q7_op2', 'carpenter_q7_op3', 'carpenter_q7_op4'], 'a': 1},
      {'q': 'carpenter_q8', 'options': ['carpenter_q8_op1', 'carpenter_q8_op2', 'carpenter_q8_op3', 'carpenter_q8_op4'], 'a': 1},
      {'q': 'carpenter_q9', 'options': ['carpenter_q9_op1', 'carpenter_q9_op2', 'carpenter_q9_op3', 'carpenter_q9_op4'], 'a': 1},
      {'q': 'carpenter_q10', 'options': ['carpenter_q10_op1', 'carpenter_q10_op2', 'carpenter_q10_op3', 'carpenter_q10_op4'], 'a': 1},
    ],
    'house_cleaner': [
      {'q': 'house_cleaner_q1', 'options': ['house_cleaner_q1_op1', 'house_cleaner_q1_op2', 'house_cleaner_q1_op3', 'house_cleaner_q1_op4'], 'a': 1},
      {'q': 'house_cleaner_q2', 'options': ['house_cleaner_q2_op1', 'house_cleaner_q2_op2', 'house_cleaner_q2_op3', 'house_cleaner_q2_op4'], 'a': 1},
      {'q': 'house_cleaner_q3', 'options': ['house_cleaner_q3_op1', 'house_cleaner_q3_op2', 'house_cleaner_q3_op3', 'house_cleaner_q3_op4'], 'a': 1},
      {'q': 'house_cleaner_q4', 'options': ['house_cleaner_q4_op1', 'house_cleaner_q4_op2', 'house_cleaner_q4_op3', 'house_cleaner_q4_op4'], 'a': 1},
      {'q': 'house_cleaner_q5', 'options': ['house_cleaner_q5_op1', 'house_cleaner_q5_op2', 'house_cleaner_q5_op3', 'house_cleaner_q5_op4'], 'a': 1},
      {'q': 'house_cleaner_q6', 'options': ['house_cleaner_q6_op1', 'house_cleaner_q6_op2', 'house_cleaner_q6_op3', 'house_cleaner_q6_op4'], 'a': 1},
      {'q': 'house_cleaner_q7', 'options': ['house_cleaner_q7_op1', 'house_cleaner_q7_op2', 'house_cleaner_q7_op3', 'house_cleaner_q7_op4'], 'a': 1},
      {'q': 'house_cleaner_q8', 'options': ['house_cleaner_q8_op1', 'house_cleaner_q8_op2', 'house_cleaner_q8_op3', 'house_cleaner_q8_op4'], 'a': 1},
      {'q': 'house_cleaner_q9', 'options': ['house_cleaner_q9_op1', 'house_cleaner_q9_op2', 'house_cleaner_q9_op3', 'house_cleaner_q9_op4'], 'a': 0},
      {'q': 'house_cleaner_q10', 'options': ['house_cleaner_q10_op1', 'house_cleaner_q10_op2', 'house_cleaner_q10_op3', 'house_cleaner_q10_op4'], 'a': 1},
    ],
    'driver': [
      {'q': 'driver_q1', 'options': ['driver_q1_op1', 'driver_q1_op2', 'driver_q1_op3', 'driver_q1_op4'], 'a': 1},
      {'q': 'driver_q2', 'options': ['driver_q2_op1', 'driver_q2_op2', 'driver_q2_op3', 'driver_q2_op4'], 'a': 1},
      {'q': 'driver_q3', 'options': ['driver_q3_op1', 'driver_q3_op2', 'driver_q3_op3', 'driver_q3_op4'], 'a': 0},
      {'q': 'driver_q4', 'options': ['driver_q4_op1', 'driver_q4_op2', 'driver_q4_op3', 'driver_q4_op4'], 'a': 1},
      {'q': 'driver_q5', 'options': ['driver_q5_op1', 'driver_q5_op2', 'driver_q5_op3', 'driver_q5_op4'], 'a': 1},
      {'q': 'driver_q6', 'options': ['driver_q6_op1', 'driver_q6_op2', 'driver_q6_op3', 'driver_q6_op4'], 'a': 1},
      {'q': 'driver_q7', 'options': ['driver_q7_op1', 'driver_q7_op2', 'driver_q7_op3', 'driver_q7_op4'], 'a': 1},
      {'q': 'driver_q8', 'options': ['driver_q8_op1', 'driver_q8_op2', 'driver_q8_op3', 'driver_q8_op4'], 'a': 1},
      {'q': 'driver_q9', 'options': ['driver_q9_op1', 'driver_q9_op2', 'driver_q9_op3', 'driver_q9_op4'], 'a': 1},
      {'q': 'driver_q10', 'options': ['driver_q10_op1', 'driver_q10_op2', 'driver_q10_op3', 'driver_q10_op4'], 'a': 1},
    ],
    'painter': [
      {'q': 'painter_q1', 'options': ['painter_q1_op1', 'painter_q1_op2', 'painter_q1_op3', 'painter_q1_op4'], 'a': 1},
      {'q': 'painter_q2', 'options': ['painter_q2_op1', 'painter_q2_op2', 'painter_q2_op3', 'painter_q2_op4'], 'a': 1},
      {'q': 'painter_q3', 'options': ['painter_q3_op1', 'painter_q3_op2', 'painter_q3_op3', 'painter_q3_op4'], 'a': 1},
      {'q': 'painter_q4', 'options': ['painter_q4_op1', 'painter_q4_op2', 'painter_q4_op3', 'painter_q4_op4'], 'a': 1},
      {'q': 'painter_q5', 'options': ['painter_q5_op1', 'painter_q5_op2', 'painter_q5_op3', 'painter_q5_op4'], 'a': 1},
      {'q': 'painter_q6', 'options': ['painter_q6_op1', 'painter_q6_op2', 'painter_q6_op3', 'painter_q6_op4'], 'a': 1},
      {'q': 'painter_q7', 'options': ['painter_q7_op1', 'painter_q7_op2', 'painter_q7_op3', 'painter_q7_op4'], 'a': 1},
      {'q': 'painter_q8', 'options': ['painter_q8_op1', 'painter_q8_op2', 'painter_q8_op3', 'painter_q8_op4'], 'a': 1},
      {'q': 'painter_q9', 'options': ['painter_q9_op1', 'painter_q9_op2', 'painter_q9_op3', 'painter_q9_op4'], 'a': 1},
      {'q': 'painter_q10', 'options': ['painter_q10_op1', 'painter_q10_op2', 'painter_q10_op3', 'painter_q10_op4'], 'a': 1},
    ],
    // Fallback for other skills with generic service questions
    'default': [
      {'q': 'default_q1', 'options': ['default_q1_op1', 'default_q1_op2', 'default_q1_op3', 'default_q1_op4'], 'a': 1},
      {'q': 'default_q2', 'options': ['default_q2_op1', 'default_q2_op2', 'default_q2_op3', 'default_q2_op4'], 'a': 1},
      {'q': 'default_q3', 'options': ['default_q3_op1', 'default_q3_op2', 'default_q3_op3', 'default_q3_op4'], 'a': 1},
      {'q': 'default_q4', 'options': ['default_q4_op1', 'default_q4_op2', 'default_q4_op3', 'default_q4_op4'], 'a': 1},
      {'q': 'default_q5', 'options': ['default_q5_op1', 'default_q5_op2', 'default_q5_op3', 'default_q5_op4'], 'a': 1},
      {'q': 'default_q6', 'options': ['default_q6_op1', 'default_q6_op2', 'default_q6_op3', 'default_q6_op4'], 'a': 1},
      {'q': 'default_q7', 'options': ['default_q7_op1', 'default_q7_op2', 'default_q7_op3', 'default_q7_op4'], 'a': 0},
      {'q': 'default_q8', 'options': ['default_q8_op1', 'default_q8_op2', 'default_q8_op3', 'default_q8_op4'], 'a': 1},
      {'q': 'default_q9', 'options': ['default_q9_op1', 'default_q9_op2', 'default_q9_op3', 'default_q9_op4'], 'a': 1},
      {'q': 'default_q10', 'options': ['default_q10_op1', 'default_q10_op2', 'default_q10_op3', 'default_q10_op4'], 'a': 0},
    ]
  };

  List<Map<String, dynamic>> _getQuestionsForSkill(String skill) {
    // Normalize skill key if necessary or mapping
    // Assuming keys match those in selection screen: 'plumber', 'electrician', etc.
    final key = skill.toLowerCase().replaceAll(' ', '_');
    
    // Return specific questions or default if not found
    List<Map<String, dynamic>> questions = _allQuestions[key] ?? _allQuestions['default']!;

    // Add translation simulation if needed (Here we append language to show logic, 
    // but typically we'd fetch localized strings. Since we hardcoded English, 
    // we just return English text.
    return questions;
  }

  void _answerQuestion(int selectedOption) {
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final questions = _getQuestionsForSkill(currentSkill);
    final correctOptionIndex = questions[_currentQuestionIndex]['a'] as int;

    if (selectedOption == correctOptionIndex) {
      _score++;
    }

    if (_currentQuestionIndex < 9) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Quiz finished for this skill
      
      // Determine Pass/Fail (8 out of 10)
      bool passed = _score >= 8;
      
      if (passed) {
        _passedSkills.add(currentSkill);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(passed ? tr('congratulations') : tr('oops')), // Ensure keys exist or use hardcoded
          content: Text(
            passed 
              ? tr('passed_quiz_for', args: [tr(currentSkill), '$_score/10'])
              : tr('failed_quiz_for', args: [tr(currentSkill), '$_score/10'])
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _moveToNextSkill();
              },
              child: Text(tr('next')),
            )
          ],
        ),
      );
    }
  }

  void _moveToNextSkill() {
    if (_currentSkillIndex < widget.selectedSkills.length - 1) {
      setState(() {
        _currentSkillIndex++;
        _currentQuestionIndex = 0;
        _score = 0;
      });
    } else {
      // All quizzes done
      if (_passedSkills.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('no_skills_passed'))),
        );
        // Optionally navigate back or show a summary
        // For now, proceed to wrapper. The wrapper handles empty passed skills.
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SkillVideoUploadWrapper(
            userId: widget.userId,
            passedSkills: _passedSkills,
            commonAnswers: widget.commonAnswers ?? {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedSkills.isEmpty) {
        return Scaffold(
            appBar: AppBar(title: Text(tr('quiz'))),
            body: Center(child: Text(tr('no_skills_selected')))
        );
    }
    
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final questions = _getQuestionsForSkill(currentSkill);
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr('quiz')}: ${tr(currentSkill)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  icon: const Icon(Icons.language),
                  items: ['English', 'Hindi', 'Telugu']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLanguage = val!;
                      // In a real app, this would trigger a reload of questions in the new language
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Progress
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / 10,
              backgroundColor: Colors.grey.shade200,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              '${tr('question')} ${_currentQuestionIndex + 1} / 10',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Question Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      tr(currentQuestion['q']),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_selectedLanguage != 'English')
                      Text(
                        '(${tr('translation_not_available_note')})', // "Translation not available for this language yet"
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Options
            ...List.generate(4, (index) {
              final optionText = (currentQuestion['options'] as List)[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  onPressed: () => _answerQuestion(index),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    alignment: Alignment.centerLeft,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300)
                    )
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr(optionText),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
