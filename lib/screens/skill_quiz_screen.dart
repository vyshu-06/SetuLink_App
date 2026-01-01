import 'package:flutter/material.dart';
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
    'gardener': [
      {'q': 'What is the process of removing dead or unwanted branches from a tree or shrub called?', 'options': ['Pruning', 'Mulching', 'Weeding', 'Tilling'], 'a': 0},
      {'q': 'Which of the following is a primary benefit of adding mulch to a garden bed?', 'options': ['It attracts pests', 'It retains soil moisture and suppresses weeds', 'It makes the soil more compact', 'It encourages fungal growth'], 'a': 1},
      {'q': 'What does "full sun" typically mean for a plant\'s light requirements?', 'options': ['At least 2 hours of direct sunlight', 'At least 6 hours of direct sunlight', 'Bright, but indirect light all day', 'Full shade'], 'a': 1},
      {'q': 'What is the ideal pH range for most garden vegetables?', 'options': ['4.5 - 5.5', '6.0 - 7.0', '7.5 - 8.5', '8.5 - 9.5'], 'a': 1},
      {'q': 'Which of these is a cool-weather crop?', 'options': ['Tomato', 'Cucumber', 'Lettuce', 'Watermelon'], 'a': 2},
      {'q': 'What is the main purpose of composting?', 'options': ['To create a sterile growing medium', 'To dispose of kitchen waste quickly', 'To create a nutrient-rich soil amendment', 'To increase soil pH'], 'a': 2},
      {'q': 'Which tool is best suited for turning soil in a new garden bed?', 'options': ['A trowel', 'A garden fork or spade', 'A leaf rake', 'A hoe'], 'a': 1},
      {'q': 'What does the term "deadheading" refer to?', 'options': ['Removing dead plants from the garden', 'Watering plants at the end of the day', 'Removing spent flowers to encourage more blooms', 'Harvesting root vegetables'], 'a': 2},
      {'q': 'Which of the following is a common sign of overwatering a plant?', 'options': ['Crispy brown leaves', 'Yellowing leaves and wilting', 'Slow growth', 'Brightly colored flowers'], 'a': 1},
      {'q': 'What is companion planting?', 'options': ['Planting two of the same plant next to each other', 'A planting method that uses a trellis', 'The practice of planting different crops in proximity for mutual benefit', 'Planting in a container with a companion'], 'a': 2},
    ],
    'mechanic': [
      {'q': 'What is the primary function of engine oil?', 'options': ['To clean the fuel injectors', 'To cool the engine', 'To lubricate moving parts and reduce friction', 'To improve fuel economy'], 'a': 2},
      {'q': 'A car\'s battery provides power to which component to start the engine?', 'options': ['The alternator', 'The starter motor', 'The fuel pump', 'The radiator fan'], 'a': 1},
      {'q': 'What does the acronym "VIN" stand for?', 'options': ['Vehicle Identification Number', 'Vehicle Inspection Notice', 'Verified Insurance Number', 'Vehicle Information Nameplate'], 'a': 0},
      {'q': 'If a car\'s brake pedal feels "spongy," what is the most likely cause?', 'options': ['Worn brake pads', 'Air in the brake lines', 'Low tire pressure', 'A failing alternator'], 'a': 1},
      {'q': 'What is the function of an alternator?', 'options': ['It starts the car', 'It cools the engine', 'It recharges the battery and powers the electrical system while the engine is running', 'It controls the vehicle\'s emissions'], 'a': 2},
      {'q': 'Which of these is a sign that your tires may need to be balanced?', 'options': ['The car pulls to one side', 'The ride is unusually bumpy', 'Vibration in the steering wheel at certain speeds', 'A squealing noise when braking'], 'a': 2},
      {'q': 'What does a catalytic converter do?', 'options': ['It converts engine heat into power', 'It reduces harmful emissions from the exhaust', 'It improves the car\'s aerodynamics', 'It helps the car start in cold weather'], 'a': 1},
      {'q': 'In a standard 4-stroke engine, what are the four strokes in order?', 'options': ['Intake, Power, Compression, Exhaust', 'Intake, Compression, Power, Exhaust', 'Compression, Intake, Power, Exhaust', 'Power, Exhaust, Intake, Compression'], 'a': 1},
      {'q': 'What is the purpose of a car\'s radiator?', 'options': ['To heat the car\'s cabin', 'To cool the engine by dissipating heat from the coolant', 'To filter the engine oil', 'To charge the battery'], 'a': 1},
      {'q': 'What does a lit "Check Engine" light signify?', 'options': ['It is time for a routine oil change', 'A tire has low pressure', 'The engine has detected a potential problem', 'The headlights are on'], 'a': 2},
    ],
    'chef': [
      {'q': 'What are the five "mother sauces" of classical French cuisine?', 'options': ['Tomato, Pesto, Alfredo, Marinara, and Aioli', 'Béchamel, Espagnole, Hollandaise, Tomate, and Velouté', 'Soy, Teriyaki, Hoisin, Oyster, and Sriracha', 'Salsa, Mole, Guacamole, Ranch, and BBQ'], 'a': 1},
      {'q': 'What does the culinary term "al dente" mean, typically used for pasta?', 'options': ['Cooked until very soft', 'Served with a cheese sauce', 'Cooked until firm to the bite', 'Served cold'], 'a': 2},
      {'q': 'What is the process of searing meat?', 'options': ['Cooking it slowly in liquid', 'Boiling it rapidly', 'Cooking it at a high temperature to create a browned crust', 'Marinating it overnight'], 'a': 2},
      {'q': 'Which knife is the most versatile and essential in a kitchen?', 'options': ['Paring knife', 'Bread knife', 'Chef\'s knife', 'Boning knife'], 'a': 2},
      {'q': 'What is the purpose of blanching vegetables?', 'options': ['To cook them fully in one step', 'To lightly cook them in boiling water then shock them in ice water to preserve color and texture', 'To roast them in the oven', 'To pickle them in vinegar'], 'a': 1},
      {'q': 'Which of the following is NOT a method of "dry-heat" cooking?', 'options': ['Roasting', 'Grilling', 'Sautéing', 'Braising'], 'a': 3},
      {'q': 'What is an "emulsion" in cooking?', 'options': ['A mixture of flour and fat used to thicken sauces', 'A combination of two liquids that normally don\'t mix, like oil and vinegar', 'A type of clear soup', 'A technique for chopping herbs'], 'a': 1},
      {'q': 'What temperature is generally considered the "danger zone" for food, where bacteria grow most rapidly?', 'options': ['Below 0°C (32°F)', '0°C to 20°C (32°F to 68°F)', '4°C to 60°C (40°F to 140°F)', 'Above 100°C (212°F)'], 'a': 2},
      {'q': 'What does it mean to "deglaze" a pan?', 'options': ['To clean a pan with soap and water', 'To add liquid to a hot pan to lift the flavorful browned bits off the bottom', 'To remove the glossy finish from a pan', 'To coat a pan with a non-stick spray'], 'a': 1},
      {'q': 'Which ingredient acts as a leavening agent in baking?', 'options': ['Sugar', 'Flour', 'Baking soda or yeast', 'Salt'], 'a': 2},
    ],
    'babysitter': [
      {'q': 'What is the first thing you should do when you arrive at a babysitting job?', 'options': ['Start playing with the children', 'Ask for the Wi-Fi password', 'Confirm emergency contact information and house rules with the parents', 'Turn on the TV'], 'a': 2},
      {'q': 'What is the correct sleep position for an infant to reduce the risk of SIDS?', 'options': ['On their stomach', 'On their side', 'On their back', 'With a soft pillow'], 'a': 2},
      {'q': 'If a child starts choking and cannot cough or make a sound, what should you do?', 'options': ['Give them a glass of water', 'Encourage them to cough', 'Immediately perform age-appropriate first aid for choking (like back blows or the Heimlich maneuver) and call for help', 'Wait for the parents to return'], 'a': 2},
      {'q': 'A toddler is having a tantrum. What is generally the best approach?', 'options': ['Yell at them to stop', 'Ignore them completely', 'Stay calm, ensure they are safe, and acknowledge their feelings without giving in to unreasonable demands', 'Offer them a sugary snack to calm them down'], 'a': 2},
      {'q': 'If a stranger comes to the door, what should you do?', 'options': ['Open the door to see what they want', 'Let the child answer the door', 'Do not open the door and do not tell the person you are alone', 'Invite them in if they say they know the parents'], 'a': 2},
      {'q': 'Which snack is a potential choking hazard for a toddler?', 'options': ['Yogurt', 'Apple slices', 'Whole grapes', 'Mashed bananas'], 'a': 2},
      {'q': 'What is a key part of ensuring a safe play environment for children?', 'options': ['Letting them play with any toys they find', 'Supervising them closely and removing any potential hazards', 'Only allowing them to watch TV', 'Letting them play outside unsupervised'], 'a': 1},
      {'q': 'If a child gets a minor cut, what is the first aid step?', 'options': ['Ignore it', 'Apply pressure with a clean cloth and then wash with soap and water', 'Cover it immediately without cleaning it', 'Put ice on it'], 'a': 1},
      {'q': 'How should you communicate with the parents during the job?', 'options': ['Only call if there is a major emergency', 'Send updates every 5 minutes', 'Follow the communication plan you agreed on with them (e.g., text with a picture or only call if needed)', 'Do not contact them at all'], 'a': 2},
      {'q': 'Before the parents leave, what crucial information should you know about each child?', 'options': ['Their favorite TV show', 'Any allergies or medical conditions', 'Their favorite toy', 'What time they go to bed'], 'a': 1},
    ],
    'pet_sitter': [
      {'q': 'What is a common sign of stress or anxiety in a dog?', 'options': ['Wagging tail', 'Panting, yawning, or excessive licking', 'A healthy appetite', 'Sleeping soundly'], 'a': 1},
      {'q': 'Which of the following common human foods is toxic to dogs?', 'options': ['Carrots', 'Chocolate', 'Rice', 'Apples'], 'a': 1},
      {'q': 'Before a client leaves, what is the most critical information to have?', 'options': ['The Wi-Fi password', 'The pet\'s favorite toys', 'Veterinarian contact information and feeding/medication schedule', 'The TV remote instructions'], 'a': 2},
      {'q': 'If you are walking a dog and another off-leash dog approaches, what should you do?', 'options': ['Let the dogs figure it out', 'Run away as fast as you can', 'Stay calm, try to create space, and place yourself between the dog you\'re walking and the other dog', 'Shout at the other dog'], 'a': 2},
      {'q': 'When meeting a new cat for the first time, what is the best approach?', 'options': ['Immediately pick it up for a cuddle', 'Stare directly into its eyes', 'Let the cat approach you first and offer a hand to sniff', 'Make loud noises to get its attention'], 'a': 2},
      {'q': 'What is a sign that a cat is feeling comfortable and content?', 'options': ['Hissing', 'A twitching tail', 'Purring and slow blinking', 'Flattened ears'], 'a': 2},
      {'q': 'If a pet in your care seems sick or injured, what should be your first step?', 'options': ['Wait 24 hours to see if it improves', 'Search for remedies online', 'Contact the owner and/or the veterinarian immediately for guidance', 'Try to give it human medication'], 'a': 2},
      {'q': 'Why is it important to keep a dog on a leash in public areas?', 'options': ['It isn\'t important if the dog is well-behaved', 'To show who is in control', 'For the safety of the dog, other people, and other animals', 'To make the walk shorter'], 'a': 2},
      {'q': 'What does it mean if a dog\'s body language is "stiff" with a high, wagging tail?', 'options': ['It is always a sign of a friendly and happy dog', 'The dog is relaxed and ready to play', 'It can be a sign of arousal or potential aggression, and should be approached with caution', 'The dog is tired'], 'a': 2},
      {'q': 'How often should a litter box for a cat typically be scooped?', 'options': ['Once a week', 'Once a month', 'At least once a day', 'Only when it looks full'], 'a': 2},
    ],

  };

  List<Map<String, dynamic>> _getQuestionsForSkill(String skill) {
    final key = skill.toLowerCase().replaceAll(' ', '_');
    return _allQuestions[key] ?? _allQuestions['default']!;
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
      bool passed = _score >= 8;
      if (passed) {
        _passedSkills.add(currentSkill);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(passed ? 'Congratulations!' : 'Oops!'),
          content: Text(
            passed
              ? 'You passed the quiz for $currentSkill with a score of $_score/10.'
              : 'You did not pass the quiz for $currentSkill. You scored $_score/10.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _moveToNextSkill();
              },
              child: Text('Next'),
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
      if (_passedSkills.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You did not pass the quiz for any of the selected skills.')),
        );
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
            appBar: AppBar(title: Text('Quiz')),
            body: Center(child: Text('No skills selected.'))
        );
    }
    
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final questions = _getQuestionsForSkill(currentSkill);
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: $currentSkill'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / 10,
              backgroundColor: Colors.grey.shade200,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              'Question ${_currentQuestionIndex + 1} / 10',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
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
