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
      {'q': 'What is the primary purpose of a P-trap in a plumbing system?', 'options': ['To increase water pressure', 'To prevent sewer gases from entering the house', 'To filter debris from the water', 'To connect pipes of different sizes'], 'a': 1},
      {'q': 'Which tool is used to tighten or loosen nuts on faucets and other plumbing fixtures?', 'options': ['Pipe wrench', 'Basin wrench', 'Hacksaw', 'Plunger'], 'a': 1},
      {'q': 'What does the term "sweating a pipe" refer to?', 'options': ['Insulating a pipe to prevent condensation', 'The process of soldering a copper pipe', 'A pipe leaking slowly', 'Using a torch to thaw a frozen pipe'], 'a': 1},
      {'q': 'Which type of valve is best for shutting off the water supply completely?', 'options': ['Gate valve', 'Globe valve', 'Check valve', 'Butterfly valve'], 'a': 0},
      {'q': 'What is the minimum recommended slope for a horizontal drainage pipe?', 'options': ['1/8 inch per foot', '1/4 inch per foot', '1/2 inch per foot', '1 inch per foot'], 'a': 1},
      {'q': 'What material is commonly used for residential water supply pipes?', 'options': ['Lead', 'Cast Iron', 'PVC', 'Copper or PEX'], 'a': 3},
      {'q': 'What should you do first if you have a clogged drain?', 'options': ['Pour chemical drain cleaner down the drain', 'Use a plunger', 'Call a plumber immediately', 'Disassemble the P-trap'], 'a': 1},
      {'q': 'What is a "water hammer"?', 'options': ['A tool used to break up old pipes', 'A banging noise in pipes when a valve is closed suddenly', 'A type of water pump', 'A device to measure water pressure'], 'a': 1},
      {'q': 'Which of these is NOT a common cause of a running toilet?', 'options': ['A faulty flapper', 'An incorrect float level', 'A broken fill valve', 'A clogged drain'], 'a': 3},
      {'q': 'What is the function of a vent stack in a plumbing system?', 'options': ['To supply hot water', 'To release pressure and allow drains to flow freely', 'To store excess water', 'To mix hot and cold water'], 'a': 1},
    ],
    'electrician': [
      {'q': 'What is the unit of electrical resistance?', 'options': ['Volt', 'Ampere', 'Ohm', 'Watt'], 'a': 2},
      {'q': 'Which type of wire is typically used for grounding in residential wiring?', 'options': ['Black wire', 'White wire', 'Bare copper or green wire', 'Red wire'], 'a': 2},
      {'q': 'What does a GFCI (Ground Fault Circuit Interrupter) do?', 'options': ['Protects against power surges', 'Prevents fires by detecting overheating wires', 'Shuts off power if it detects a small leak in the current', 'Acts as a main switch for the entire house'], 'a': 2},
      {'q': 'What is the standard voltage for a residential outlet in the US?', 'options': ['110V', '120V', '220V', '240V'], 'a': 1},
      {'q': 'Which of the following is the correct formula for Ohm\'s Law?', 'options': ['V = I * R', 'P = V * I', 'R = V / P', 'I = P / V'], 'a': 0},
      {'q': 'What is the purpose of a circuit breaker?', 'options': ['To step up voltage', 'To provide a path for lightning to ground', 'To automatically stop the flow of current in case of an overload or short circuit', 'To store electrical energy'], 'a': 2},
      {'q': 'When wiring a single-pole switch, which wire should be connected to the switch?', 'options': ['The neutral (white) wire', 'The hot (black) wire', 'The ground (green) wire', 'Both the hot and neutral wires'], 'a': 1},
      {'q': 'What does "AWG" stand for in the context of electrical wires?', 'options': ['American Wire Gauge', 'Alternating Wire Grade', 'Applied Wattage Guide', 'Associated Wire Group'], 'a': 0},
      {'q': 'Which of the following is a potential sign of an overloaded circuit?', 'options': ['Lights flickering or dimming', 'A buzzing sound from an outlet', 'A burning smell from a switch or outlet', 'All of the above'], 'a': 3},
      {'q': 'What should be the first step before working on any electrical circuit?', 'options': ['Put on rubber gloves', 'Turn off the power at the circuit breaker or fuse box', 'Notify others in the house', 'Test the wires with a multimeter'], 'a': 1},
    ],
    'carpenter': [
      {'q': 'Which saw is best for making curved cuts?', 'options': ['Circular saw', 'Miter saw', 'Jigsaw', 'Table saw'], 'a': 2},
      {'q': 'What is the purpose of a pilot hole?', 'options': ['To make a decorative hole', 'To prevent wood from splitting when a screw is driven in', 'To check the depth of the wood', 'To start a nail'], 'a': 1},
      {'q': 'What does the term "MDF" stand for?', 'options': ['Medium-density fiberboard', 'Multi-directional frame', 'Main structural frame', 'Moisture-durable flooring'], 'a': 0},
      {'q': 'Which joint is commonly used to join the corners of a picture frame?', 'options': ['Butt joint', 'Dovetail joint', 'Miter joint', 'Lap joint'], 'a': 2},
      {'q': 'What is a "level" used for?', 'options': ['To measure angles', 'To ensure a surface is perfectly horizontal or vertical', 'To draw straight lines', 'To sand wood smoothly'], 'a': 1},
      {'q': 'Which of these is a type of hardwood?', 'options': ['Pine', 'Cedar', 'Oak', 'Spruce'], 'a': 2},
      {'q': 'What is "kickback" in the context of using a table saw?', 'options': ['The wood piece being suddenly thrown back towards the operator', 'The saw blade stopping abruptly', 'A type of saw blade guard', 'The noise the saw makes when starting'], 'a': 0},
      {'q': 'What is the main advantage of using a "dado" blade?', 'options': ['It makes very fine cuts', 'It can cut wide grooves or channels in a single pass', 'It is designed for cutting metal', 'It requires less power'], 'a': 1},
      {'q': 'When sanding wood, which of the following is the correct procedure?', 'options': ['Start with a fine-grit sandpaper and move to a coarse-grit', 'Start with a coarse-grit sandpaper and move to a fine-grit', 'Use only one grit of sandpaper throughout the process', 'Sand against the grain of the wood'], 'a': 1},
      {'q': 'What is a "stud finder" used for?', 'options': ['To locate the wooden beams (studs) inside a wall', 'To find lost nails and screws', 'To measure the thickness of a wall', 'To check for live wires in a wall'], 'a': 0},
    ],
    'house_cleaner': [
      {'q': 'Which cleaning agent is best for cutting through grease?', 'options': ['Vinegar', 'Baking soda', 'A solution with a degreaser or dish soap', 'Glass cleaner'], 'a': 2},
      {'q': 'What is the most effective way to remove dust from furniture?', 'options': ['Using a dry cloth', 'Using a feather duster', 'Using a damp microfiber cloth', 'Blowing it off'], 'a': 2},
      {'q': 'How should you clean stainless steel appliances to avoid streaks?', 'options': ['Wipe in a circular motion', 'Wipe with a dry paper towel', 'Wipe in the direction of the grain', 'Use a harsh abrasive cleaner'], 'a': 2},
      {'q': 'Which of these should be used to disinfect a kitchen countertop?', 'options': ['Water only', 'A solution of bleach and water, or a disinfectant spray', 'Dish soap', 'A dry cloth'], 'a': 1},
      {'q': 'What is the first step in cleaning a bathroom?', 'options': ['Clean the toilet', 'Mop the floor', 'Remove all items from surfaces', 'Clean the mirror'], 'a': 2},
      {'q': 'Which of the following is NOT recommended for cleaning hardwood floors?', 'options': ['A microfiber mop', 'A pH-neutral cleaner', 'Using a large amount of water', 'Sweeping or vacuuming regularly'], 'a': 2},
      {'q': 'What is a common use for baking soda in cleaning?', 'options': ['As a disinfectant', 'To polish silver', 'To absorb odors and as a mild abrasive', 'To clean windows'], 'a': 2},
      {'q': 'How often should you deep clean a refrigerator?', 'options': ['Every week', 'Every month', 'Every 3-4 months', 'Once a year'], 'a': 2},
      {'q': 'What is the best way to treat a fresh red wine spill on a carpet?', 'options': ['Rub it vigorously with a wet cloth', 'Blot the spill and then apply salt or a specialized stain remover', 'Ignore it until it dries', 'Pour white wine on it'], 'a': 1},
      {'q': 'When cleaning windows, what is the best technique to avoid streaks?', 'options': ['Use a squeegee and wipe the blade after each pass', 'Use circular motions with a paper towel', 'Clean on a bright, sunny day', 'Use a vinegar and water solution only'], 'a': 0},
    ],
    'driver': [
      {'q': 'What does a solid yellow line on your side of the road mean?', 'options': ['You may pass with caution', 'No passing', 'The road is narrowing', 'A school zone is ahead'], 'a': 1},
      {'q': 'When should you use your high-beam headlights?', 'options': ['In foggy conditions', 'On open roads with no other cars around', 'In heavy rain', 'During the daytime'], 'a': 1},
      {'q': 'What is the "three-second rule"?', 'options': ['A rule for how long to stop at a stop sign', 'A way to ensure a safe following distance', 'The time it takes to change a tire', 'A rule for parallel parking'], 'a': 1},
      {'q': 'If you start to hydroplane, what should you do?', 'options': ['Slam on the brakes', 'Turn the steering wheel sharply', 'Ease your foot off the gas and steer straight', 'Accelerate to gain traction'], 'a': 2},
      {'q': 'What does a flashing red traffic light mean?', 'options': ['Stop and proceed when it is safe', 'Slow down and proceed with caution', 'The light is about to turn green', 'Yield to oncoming traffic'], 'a': 0},
      {'q': 'In which situation should you yield the right-of-way?', 'options': ['When you are on a larger road', 'When a pedestrian is in a crosswalk', 'When you are driving faster than the other car', 'At a green light'], 'a': 1},
      {'q': 'What is "blind spot"?', 'options': ['The area behind your car you can\'t see in the rearview mirror', 'The area around your vehicle that is not visible in your mirrors', 'A spot on the road with poor lighting', 'A part of the engine that is hard to reach'], 'a': 1},
      {'q': 'When parking uphill with a curb, which way should you turn your wheels?', 'options': ['Towards the curb', 'Straight ahead', 'Away from the curb', 'It doesn\'t matter'], 'a': 2},
      {'q': 'What is the best way to handle a tire blowout?', 'options': ['Brake hard and swerve to the side of the road', 'Hold the steering wheel firmly and ease off the gas', 'Accelerate to regain control', 'Immediately pull over'], 'a': 1},
      {'q': 'What does "defensive driving" mean?', 'options': ['Driving slowly at all times', 'Being constantly aware of your surroundings and anticipating potential hazards', 'Only driving during daylight hours', 'Aggressively claiming your right-of-way'], 'a': 1},
    ],
    'painter': [
      {'q': 'What is the first step you should take before painting a room?', 'options': ['Start painting the trim', 'Clean the walls and prep the surfaces', 'Open a window for ventilation', 'Cover the furniture'], 'a': 1},
      {'q': 'What is "primer" used for?', 'options': ['To add a glossy finish to the paint', 'To create a uniform surface for the paint to adhere to', 'To thin the paint', 'To clean brushes after painting'], 'a': 1},
      {'q': 'Which type of paint finish is the most durable and easiest to clean?', 'options': ['Matte', 'Eggshell', 'Satin', 'Semi-gloss or gloss'], 'a': 3},
      {'q': 'What is the best tool for painting the edges and corners of a wall?', 'options': ['A wide roller', 'A paint sprayer', 'An angled brush', 'A paint pad'], 'a': 2},
      {'q': 'What does the term "cutting in" refer to?', 'options': ['Using a razor to remove old paint', 'Painting a clean line where the wall meets the ceiling or trim', 'Mixing two paint colors together', 'Sanding between coats of paint'], 'a': 1},
      {'q': 'How long should you typically wait between coats of latex paint?', 'options': ['30 minutes', '1 hour', '2-4 hours', '24 hours'], 'a': 2},
      {'q': 'What is the purpose of "taping off" before painting?', 'options': ['To create a decorative pattern', 'To protect trim, windows, and other areas from paint', 'To reinforce the wall', 'To mark where to stop painting'], 'a': 1},
      {'q': 'Which type of paint is better for a high-moisture area like a bathroom?', 'options': ['Oil-based paint', 'Latex paint with a mildew-resistant additive', 'Chalk paint', 'Any interior paint'], 'a': 1},
      {'q': 'What is the best way to clean a paintbrush used with latex paint?', 'options': ['With mineral spirits', 'With soap and water', 'Throw it away', 'Let it dry and scrape the paint off'], 'a': 1},
      {'q': 'If you see paint bubbling or peeling, what is the most likely cause?', 'options': ['The paint color is too dark', 'The paint was applied in a room that was too cold', 'Moisture or dirt under the paint', 'The paint was applied too thickly'], 'a': 2},
    ],
    // Fallback for other skills with generic service questions
    'default': [
      {'q': 'How do you ensure customer satisfaction?', 'options': ['By completing the job as quickly as possible', 'By providing high-quality work and clear communication', 'By offering the lowest price', 'By only doing what is explicitly asked'], 'a': 1},
      {'q': 'What is the first step you take when you receive a new service request?', 'options': ['Immediately go to the customer\'s location', 'Contact the customer to understand the requirements and schedule a visit', 'Purchase all possible materials', 'Ask for payment upfront'], 'a': 1},
      {'q': 'How do you handle a situation where a customer is unhappy with your work?', 'options': ['Argue with the customer', 'Ignore their complaints', 'Listen to their concerns and offer to fix the issue', 'Blame the tools or materials'], 'a': 2},
      {'q': 'What is the most important aspect of safety on the job?', 'options': ['Wearing the correct personal protective equipment (PPE)', 'Working quickly', 'Assuming the customer has made the area safe', 'Using the cheapest tools'], 'a': 0},
      {'q': 'How do you provide an estimate for a job?', 'options': ['Guess a random number', 'Assess the materials and labor required, then provide a detailed quote', 'Charge by the hour only', 'Give a price higher than you expect it to cost'], 'a': 1},
      {'q': 'What should you do if a job is taking longer than expected?', 'options': ['Leave the job unfinished', 'Communicate the delay to the customer and explain the reason', 'Work faster, even if it compromises quality', 'Charge the customer extra without notice'], 'a': 1},
      {'q': 'What is the best way to maintain your tools?', 'options': ['Clean and inspect them regularly', 'Leave them outside', 'Only buy new tools for every job', 'Share them with other workers'], 'a': 0},
      {'q': 'How do you handle unexpected problems during a job?', 'options': ['Panic and stop working', 'Assess the problem, and if necessary, discuss the solution and any cost changes with the customer', 'Hide the problem from the customer', 'Try a quick fix that might not last'], 'a': 1},
      {'q': 'What is the best way to build a good reputation as a service provider?', 'options': ['Through expensive advertising', 'By being reliable, professional, and delivering quality work', 'By offering discounts to everyone', 'By finishing jobs faster than anyone else'], 'a': 1},
      {'q': 'What do you do after you have completed a job?', 'options': ['Leave the site immediately', 'Clean up the work area and ask the customer to inspect the work', 'Ask for a tip', 'Send the bill a month later'], 'a': 1},
    ]
  };

  List<Map<String, dynamic>> _getQuestionsForSkill(String skill) {
    // Normalize skill key if necessary or mapping
    // Assuming keys match those in selection screen: 'plumber', 'electrician', etc.
    final key = skill.toLowerCase().replaceAll(' ', '_');
    
    // Return specific questions or default if not found
    List<Map<String, dynamic>> questions = _allQuestions[key] ?? _allQuestions['default']!;

    // Add translation simulation if needed (Here we append language to show logic, 
    // but typically we\'d fetch localized strings. Since we hardcoded English, 
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
              ? tr('passed_quiz_for', args: [currentSkill, '$_score/10'])
              : tr('failed_quiz_for', args: [currentSkill, '$_score/10'])
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
        title: Text('${tr('quiz')}: $currentSkill'),
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
                      currentQuestion['q'],
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
                          optionText,
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
