import 'package:flutter/material.dart';
import 'package:setulink_app/screens/skill_video_upload_wrapper.dart';
import 'package:setulink_app/theme/app_colors.dart';

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

class _SkillQuizScreenState extends State<SkillQuizScreen> with SingleTickerProviderStateMixin {
  int _currentSkillIndex = 0;
  int _currentQuestionIndex = 0;
  int _score = 0;
  final List<String> _passedSkills = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    ],
  };

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

  void _nextQuestion(int selectedOption) {
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final currentQuestions = _allQuestions[currentSkill]!;
    if (selectedOption == currentQuestions[_currentQuestionIndex]['a']) {
      _score++;
    }

    if (_currentQuestionIndex < currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // End of quiz for the current skill
      if (_score >= 6) {
        // Passing score
        _passedSkills.add(currentSkill);
      }
      _moveToNextSkill();
    }
  }

  void _moveToNextSkill() {
    if (_currentSkillIndex < widget.selectedSkills.length - 1) {
      setState(() {
        _currentSkillIndex++;
        _currentQuestionIndex = 0;
        _score = 0;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      // All quizzes are finished
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SkillVideoUploadWrapper(
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
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final currentQuestions = _allQuestions[currentSkill]!;
    final question = currentQuestions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Skill Quiz: $currentSkill'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.8),
              AppColors.accentColor.withOpacity(0.6),
            ],
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
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Question ${_currentQuestionIndex + 1}/${currentQuestions.length}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          question['q'],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        ...List.generate(question['options'].length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ElevatedButton(
                              onPressed: () => _nextQuestion(index),
                              child: Text(question['options'][index]),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
