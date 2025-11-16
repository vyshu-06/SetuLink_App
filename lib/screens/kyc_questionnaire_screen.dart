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
      'question': 'How many years of experience do you have in your craft?',
      'type': 'number',
      'field': 'experienceYears'
    },
    {
      'question': 'Are you certified or formally trained?',
      'type': 'boolean',
      'field': 'certified'
    },
    {
      'question': 'Do you own your own tools and materials?',
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
          decoration: InputDecoration(hintText: context.tr('enter_a_number')),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return context.tr('please_enter_value');
            }
            if (int.tryParse(val) == null) {
              return context.tr('enter_valid_number');
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
          items: [context.tr('yes'), context.tr('no')]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          validator: (val) => val == null ? context.tr('please_select_option') : null,
          onSaved: (val) {
            answers[question['field']] = val == context.tr('yes');
          },
          onChanged: (_) {},
        );
        break;
      default:
        inputWidget = Container();
    }

    return Scaffold(
      appBar: AppBar(title: Text('${context.tr('skill_verification_title')} - ${currentQuestionIndex + 1}/${questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(question['question'], style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              inputWidget,
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentQuestionIndex > 0)
                    TextButton(
                        onPressed: () => setState(() => currentQuestionIndex--),
                        child: Text(context.tr('back'))),
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
                        ? context.tr('next')
                        : context.tr('complete')),
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
