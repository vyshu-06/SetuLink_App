import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class KYCQuestionnaireScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onCompleted;
  const KYCQuestionnaireScreen({required this.onCompleted, Key? key}) : super(key: key);

  @override
  State<KYCQuestionnaireScreen> createState() => _KYCQuestionnaireScreenState();
}

class _KYCQuestionnaireScreenState extends State<KYCQuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  int currentQuestionIndex = 0;

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'kyc_question_1',
      'type': 'number',
      'field': 'experienceYears'
    },
    {
      'question': 'kyc_question_2',
      'type': 'boolean',
      'field': 'certified'
    },
    {
      'question': 'kyc_question_3',
      'type': 'boolean',
      'field': 'ownsTools'
    },
  ];

  Map<String, dynamic> answers = {};

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];

    Widget inputWidget;

    switch (question['type']) {
      case 'number':
        inputWidget = TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: tr('enter_a_number')),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return tr('please_enter_value');
            }
            if (int.tryParse(val) == null) {
              return tr('enter_valid_number');
            }
            return null;
          },
          onSaved: (val) {
            answers[question['field']] = int.parse(val!);
          },
        );
        break;
      case 'boolean':
        inputWidget = DropdownButtonFormField<String>(
          items: [tr('yes'), tr('no')]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          validator: (val) => val == null ? tr('please_select_option') : null,
          onSaved: (val) {
            answers[question['field']] = val == tr('yes');
          },
          onChanged: (_) {},
        );
        break;
      default:
        inputWidget = Container();
    }

    return Scaffold(
      appBar: AppBar(title: Text('${tr('skill_verification')} - ${currentQuestionIndex + 1}/${questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(tr(question['question']), style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              inputWidget,
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentQuestionIndex > 0)
                    TextButton(
                        onPressed: () => setState(() => currentQuestionIndex--),
                        child: Text(tr('back'))),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        if (currentQuestionIndex < questions.length - 1) {
                          setState(() {
                            currentQuestionIndex++;
                          });
                        } else {
                          widget.onCompleted(answers);
                        }
                      }
                    },
                    child: Text(currentQuestionIndex < questions.length - 1
                        ? tr('next')
                        : tr('complete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
