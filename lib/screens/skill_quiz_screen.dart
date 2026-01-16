import 'package:flutter/material.dart';
import 'package:setulink_app/screens/skill_video_upload_wrapper.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

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
      {'q': 'What is the standard height for a kitchen sink drain?', 'options': ['12 inches', '18 inches', '24 inches', '30 inches'], 'a': 1},
      {'q': 'Which tool is primarily used to clear a clogged toilet?', 'options': ['Plunger', 'Toilet Auger', 'Pipe Wrench', 'Basin Wrench'], 'a': 1},
      {'q': 'What does "PEX" stand for in plumbing?', 'options': ['Poly-Extra', 'Cross-linked Polyethylene', 'Pressure Exit', 'Pipe Extension'], 'a': 1},
      {'q': 'A blue handle on a shut-off valve usually indicates what?', 'options': ['Cold water', 'Hot water', 'Gas line', 'Drainage'], 'a': 0},
      {'q': 'What is the purpose of a P-trap?', 'options': ['To trap hair', 'To prevent sewer gases from entering', 'To increase water pressure', 'To catch dropped jewelry'], 'a': 1},
      {'q': 'Which material is used to seal pipe threads?', 'options': ['Glue', 'Teflon Tape', 'Solder', 'Duct Tape'], 'a': 1},
      {'q': 'What causes "water hammer" in pipes?', 'options': ['Air bubbles', 'Low pressure', 'Sudden shut-off of water flow', 'Leaking valves'], 'a': 2},
      {'q': 'Which pipe is used for hot water distribution?', 'options': ['PVC', 'CPVC', 'ABS', 'Cast Iron'], 'a': 1},
      {'q': 'What tool is used to tighten a nut on a sink faucet in a tight space?', 'options': ['Pipe wrench', 'Basin wrench', 'Pliers', 'Hacksaw'], 'a': 1},
      {'q': 'What is the main purpose of a vent pipe?', 'options': ['Let water out', 'Regulate air pressure in drainage', 'Heat water', 'Prevent leaks'], 'a': 1},
    ],
    'electrician': [
      {'q': 'What is the unit of electrical resistance?', 'options': ['Ampere', 'Volt', 'Ohm', 'Watt'], 'a': 2},
      {'q': 'What does a GFCI outlet protect against?', 'options': ['Short circuits', 'Power surges', 'Ground faults', 'Overloading'], 'a': 2},
      {'q': 'In standard wiring, what color is the neutral wire?', 'options': ['Black', 'Red', 'White', 'Green'], 'a': 2},
      {'q': 'Which device measures voltage?', 'options': ['Ammeter', 'Multimeter', 'Ohmmeter', 'Wattmeter'], 'a': 1},
      {'q': 'What is the main purpose of a circuit breaker?', 'options': ['Stop overload current', 'Increase voltage', 'Save electricity', 'Change DC to AC'], 'a': 0},
      {'q': 'What gauge wire is thicker?', 'options': ['14 gauge', '12 gauge', '10 gauge', '8 gauge'], 'a': 3},
      {'q': 'What is the purpose of a ground wire?', 'options': ['Carry power', 'Provide a safe path for fault current', 'Complete the circuit', 'Increase speed'], 'a': 1},
      {'q': 'Which tool is used to test if a wire is live without touching it?', 'options': ['Voltmeter', 'Non-contact voltage tester', 'Pliers', 'Wire stripper'], 'a': 1},
      {'q': 'What does "AC" stand for?', 'options': ['Actual Current', 'Alternating Current', 'Amperage Circuit', 'Active Current'], 'a': 1},
      {'q': 'What is a "Short Circuit"?', 'options': ['A very small wire', 'Unintended path for current', 'A broken bulb', 'A timed light'], 'a': 1},
    ],
    'carpenter': [
      {'q': 'Which saw is best for making curved cuts?', 'options': ['Miter Saw', 'Circular Saw', 'Jigsaw', 'Hand Saw'], 'a': 2},
      {'q': 'What tool checks if a surface is vertical?', 'options': ['Plumb bob', 'Level', 'Square', 'Chalk line'], 'a': 0},
      {'q': 'What type of joint is shaped like a bird\'s tail?', 'options': ['Miter', 'Butt', 'Dovetail', 'Lap'], 'a': 2},
      {'q': 'Which wood is a "hardwood"?', 'options': ['Pine', 'Oak', 'Cedar', 'Spruce'], 'a': 1},
      {'q': 'What is the purpose of a pilot hole?', 'options': ['Hide screw', 'Measure depth', 'Prevent splitting', 'Lubricate'], 'a': 2},
      {'q': 'What does "nominal size" mean (e.g., 2x4)?', 'options': ['Exact size', 'Size before surfacing', 'Weight', 'Length'], 'a': 1},
      {'q': 'What tool is used to smooth long pieces of wood?', 'options': ['Chisel', 'Planer', 'Rasp', 'Hammer'], 'a': 1},
      {'q': 'What is "grit" in sandpaper?', 'options': ['Weight', 'Coarseness', 'Color', 'Stickiness'], 'a': 1},
      {'q': 'Standard spacing for wall studs?', 'options': ['12 inches', '16 inches', '24 inches', '30 inches'], 'a': 1},
      {'q': 'Which glue is most common for wood?', 'options': ['Super glue', 'PVA glue', 'Epoxy', 'Hot glue'], 'a': 1},
    ],
    'house_cleaner': [
      {'q': 'What should NEVER be mixed with bleach?', 'options': ['Water', 'Dish soap', 'Ammonia', 'Baking soda'], 'a': 2},
      {'q': 'Which direction should you clean a room?', 'options': ['Bottom to top', 'Randomly', 'Top to bottom', 'Window to door'], 'a': 2},
      {'q': 'How do you remove limescale from a showerhead?', 'options': ['Soap', 'Oil', 'Vinegar soak', 'Hot water'], 'a': 2},
      {'q': 'What surface should NOT be cleaned with vinegar?', 'options': ['Glass', 'Marble', 'Ceramic', 'Steel'], 'a': 1},
      {'q': 'What is "dwell time" for a disinfectant?', 'options': ['Drying time', 'Bottle life', 'Time needed to kill germs', 'Spray time'], 'a': 2},
      {'q': 'Best cloth for streak-free mirrors?', 'options': ['Cotton', 'Microfiber', 'Paper towel', 'Wool'], 'a': 1},
      {'q': 'How to remove pet hair from fabric?', 'options': ['Feather duster', 'Damp rubber glove', 'Broom', 'Dry towel'], 'a': 1},
      {'q': 'Purpose of HEPA filter?', 'options': ['Quietness', 'Suction power', 'Trap small particles/allergens', 'Motor cooling'], 'a': 2},
      {'q': 'To avoid streaks on floors, you should...', 'options': ['Use more soap', 'Change water frequently', 'Use hot water', 'Clean once a month'], 'a': 1},
      {'q': 'Which chemical is best for cutting grease?', 'options': ['Acid', 'Alkaline/Degreaser', 'Water', 'Salt'], 'a': 1},
    ],
    'cook': [
      {'q': 'What is the "danger zone" for food temp?', 'options': ['0-32°F', '40-140°F', '160-200°F', 'Over 212°F'], 'a': 1},
      {'q': 'What does "Mise en place" mean?', 'options': ['Dessert', 'Prep ingredients ready', 'Knife cut', 'Cleaning'], 'a': 1},
      {'q': 'What is the workhorse knife of a kitchen?', 'options': ['Paring', 'Bread', 'Chef\'s', 'Boning'], 'a': 2},
      {'q': 'What does "Al dente" mean?', 'options': ['Soft', 'Firm to the bite', 'Overcooked', 'Cold'], 'a': 1},
      {'q': 'Main ingredient in Bechamel sauce?', 'options': ['Stock', 'Milk and Roux', 'Tomato', 'Oil'], 'a': 1},
      {'q': 'Internal temp for cooked chicken?', 'options': ['145°F', '155°F', '165°F', '175°F'], 'a': 2},
      {'q': 'What is "searing"?', 'options': ['Boiling', 'Browning surface at high heat', 'Slow cooking', 'Steaming'], 'a': 1},
      {'q': 'What does "Julienne" mean?', 'options': ['Small cubes', 'Matchstick strips', 'Thin slices', 'Rough chop'], 'a': 1},
      {'q': 'How to stop a grease fire?', 'options': ['Water', 'Cover with lid/Baking soda', 'Blow on it', 'Flour'], 'a': 1},
      {'q': 'What leavening agent reacts with acid?', 'options': ['Yeast', 'Baking Soda', 'Baking Powder', 'Salt'], 'a': 1},
    ],
    'gardener': [
      {'q': 'Best time of day to water plants?', 'options': ['Mid-day', 'Early morning', 'Late night', 'Afternoon'], 'a': 1},
      {'q': 'What does "Deadheading" mean?', 'options': ['Killing bugs', 'Removing faded flowers', 'Cutting stems', 'Weeding'], 'a': 1},
      {'q': 'What are fertilizer NPK nutrients?', 'options': ['Nitrogen, Phosphorus, Potassium', 'Neon, Potassium, Krypton', 'Nickel, Phosphate, Kalium', 'Nitrogen, Protein, Keratin'], 'a': 0},
      {'q': 'Purpose of mulch?', 'options': ['Attract bugs', 'Retain moisture', 'Harden soil', 'Shade'], 'a': 1},
      {'q': 'Tool for pruning small branches?', 'options': ['Shears', 'Chainsaw', 'Hand Pruners', 'Shovel'], 'a': 2},
      {'q': 'What is "composting"?', 'options': ['Adding sand', 'Decomposing organic waste for nutrients', 'Planting seeds', 'Watering'], 'a': 1},
      {'q': 'Cool-weather crop example?', 'options': ['Tomato', 'Watermelon', 'Lettuce', 'Pepper'], 'a': 2},
      {'q': 'Purpose of "tilling"?', 'options': ['Aerate soil', 'Add water', 'Kill plants', 'Level ground'], 'a': 0},
      {'q': 'Sign of overwatering?', 'options': ['Crispy leaves', 'Yellowing/Wilting leaves', 'Fast growth', 'Bright colors'], 'a': 1},
      {'q': 'What is "Full Sun"?', 'options': ['2 hours', '4 hours', '6+ hours', 'Direct noon only'], 'a': 2},
    ],
    'tailor': [
      {'q': 'Standard seam allowance for most patterns?', 'options': ['1/4 inch', '5/8 inch', '1 inch', '1/2 inch'], 'a': 1},
      {'q': 'What does "grainline" refer to?', 'options': ['Fabric color', 'Direction of threads', 'Fabric weight', 'Thread thickness'], 'a': 1},
      {'q': 'Tool used to finish raw edges?', 'options': ['Straight stitch', 'Serger/Overlocker', 'Zipper foot', 'Seam ripper'], 'a': 1},
      {'q': 'What is "basting"?', 'options': ['Final stitch', 'Temporary long stitch', 'Ironing', 'Cutting'], 'a': 1},
      {'q': 'Purpose of an interface?', 'options': ['Add color', 'Add stiffness/support', 'Make it waterproof', 'Join two pieces'], 'a': 1},
      {'q': 'What is "selvage"?', 'options': ['The finished edge of fabric', 'A type of button', 'Thread scrap', 'The center of fabric'], 'a': 0},
      {'q': 'A "dart" is used to...', 'options': ['Add length', 'Create shape/contour', 'Hem pants', 'Attach buttons'], 'a': 1},
      {'q': 'What is "notching"?', 'options': ['Measuring', 'Cutting slits in curves to lay flat', 'Sewing fast', 'Ironing seams'], 'a': 1},
      {'q': 'Which needle is for knits?', 'options': ['Sharp', 'Ballpoint', 'Leather', 'Jeans'], 'a': 1},
      {'q': 'What does "preshrinking" mean?', 'options': ['Washing fabric before sewing', 'Ironing', 'Drying', 'Cutting smaller'], 'a': 0},
    ],
    'painter': [
      {'q': 'Purpose of primer?', 'options': ['Change color', 'Adhesion/Sealing', 'Fast drying', 'Thinning'], 'a': 1},
      {'q': 'Best finish for bathrooms?', 'options': ['Flat', 'Matte', 'Semi-gloss', 'Eggshell'], 'a': 2},
      {'q': 'What is "cutting in"?', 'options': ['Thinning', 'Painting edges first', 'Mixing', 'Scraping'], 'a': 1},
      {'q': 'Prep for glossy surfaces?', 'options': ['Nothing', 'More paint', 'Sanding', 'Soap wash'], 'a': 2},
      {'q': 'Roller nap for smooth walls?', 'options': ['1/4 inch', '1/2 inch', '3/4 inch', '1 inch'], 'a': 0},
      {'q': 'What is "latex paint"?', 'options': ['Oil-based', 'Water-based', 'Rubber-based', 'Metal-based'], 'a': 1},
      {'q': 'Purpose of Painter\'s Tape?', 'options': ['Hang pictures', 'Protect edges/Clean lines', 'Fix cracks', 'Stir paint'], 'a': 1},
      {'q': 'What is "tack cloth" used for?', 'options': ['Cover floor', 'Remove fine dust', 'Apply wax', 'Clean brushes'], 'a': 1},
      {'q': 'Best way to clean latex brushes?', 'options': ['Mineral spirits', 'Soap and water', 'Acetone', 'Dry them'], 'a': 1},
      {'q': 'When should you remove tape?', 'options': ['While paint is damp', 'After 2 days', 'Before painting', 'Never'], 'a': 0},
    ],
    'babysitter': [
      {'q': 'Safest infant sleep position?', 'options': ['Stomach', 'Side', 'Back', 'With blankets'], 'a': 2},
      {'q': 'Action for a choking child?', 'options': ['CPR', 'Heimlich maneuver', 'Water', 'Pat back'], 'a': 1},
      {'q': 'Important info from parents?', 'options': ['Wi-Fi', 'Emergency contacts/Allergies', 'Movies', 'Dinner'], 'a': 1},
      {'q': 'How to handle a tantrum?', 'options': ['Yell', 'Stay calm and safe', 'Candy', 'Leave'], 'a': 1},
      {'q': 'First step in an emergency?', 'options': ['Call parents', 'Check safety and 911', 'Panic', 'Wait'], 'a': 1},
      {'q': 'Stranger at the door policy?', 'options': ['Invite in', 'Open door', 'Don\'t open/Don\'t say alone', 'Ask name'], 'a': 2},
      {'q': 'Infant soft spot location?', 'options': ['Back', 'Top of head', 'Chest', 'Stomach'], 'a': 1},
      {'q': 'Snack hazard for toddlers?', 'options': ['Mashed banana', 'Whole grapes', 'Yogurt', 'Apple sauce'], 'a': 1},
      {'q': 'Before changing a diaper, you should...', 'options': ['Wash hands', 'Gather all supplies', 'Call parents', 'Put on TV'], 'a': 1},
      {'q': 'Bedtime best practice?', 'options': ['Let them play', 'Follow established routine', 'Wait for them to fall asleep', 'Sugar snacks'], 'a': 1},
    ],
    'laundry': [
      {'q': 'Which temp for white cottons?', 'options': ['Cold', 'Warm', 'Hot', 'Room temp'], 'a': 2},
      {'q': 'Symbol for "Do Not Iron"?', 'options': ['Circle', 'Iron with X', 'Square', 'Triangle'], 'a': 1},
      {'q': 'What removes grease stains?', 'options': ['Water', 'Dish soap', 'Vinegar', 'Salt'], 'a': 1},
      {'q': 'Purpose of fabric softener?', 'options': ['Clean better', 'Reduce static/soften', 'Remove stains', 'Bleach'], 'a': 1},
      {'q': 'Best way to dry wool?', 'options': ['Tumble dry', 'Hang high', 'Flat dry', 'Direct sun'], 'a': 2},
      {'q': 'Laundry symbol with a triangle?', 'options': ['Wash', 'Bleach', 'Dry', 'Iron'], 'a': 1},
      {'q': 'What to do with new red clothes?', 'options': ['Wash with whites', 'Wash separately', 'Don\'t wash', 'Use bleach'], 'a': 1},
      {'q': 'Reason to turn clothes inside out?', 'options': ['Clean better', 'Protect colors/prints', 'Dries faster', 'Easier to fold'], 'a': 1},
      {'q': 'Purpose of a "delicates" bag?', 'options': ['Save space', 'Protect fragile items', 'Keep socks together', 'Use less water'], 'a': 1},
      {'q': 'What does "Dry Clean Only" mean?', 'options': ['Wash cold', 'Professional cleaning required', 'Hand wash', 'Steam only'], 'a': 1},
    ],
    'elderly_caregiver': [
      {'q': 'Primary goal of "fall prevention"?', 'options': ['Stop movement', 'Clear hazards/clutter', 'Bed rest', 'Using chairs'], 'a': 1},
      {'q': 'Sign of dehydration?', 'options': ['High energy', 'Confusion/Dry mouth', 'Sweating', 'Hunger'], 'a': 1},
      {'q': 'How to help with limited mobility?', 'options': ['Lift them', 'Use gait belt/assistive devices', 'Pull arms', 'Let them fall'], 'a': 1},
      {'q': 'Important for medication?', 'options': ['Guess timing', 'Right dose/Right time', 'Skip if sleeping', 'Mix with juice'], 'a': 1},
      {'q': 'First aid for pressure sores?', 'options': ['Frequent repositioning', 'Hot water', 'Massage', 'Tight bandages'], 'a': 0},
      {'q': 'Communicating with hearing-impaired?', 'options': ['Shout', 'Face them and speak clearly', 'Speak fast', 'Use phone'], 'a': 1},
      {'q': 'Sign of a stroke?', 'options': ['Hunger', 'Facial drooping/Slurred speech', 'Sneezing', 'Back pain'], 'a': 1},
      {'q': 'Dementia patient strategy?', 'options': ['Argue facts', 'Routine and patience', 'Test memory', 'Leave alone'], 'a': 1},
      {'q': 'Proper way to assist walking?', 'options': ['Walk in front', 'Walk slightly behind/at side', 'Walk far away', 'Push'], 'a': 1},
      {'q': 'Importance of hydration?', 'options': ['None', 'Prevents UTIs/Confusion', 'Makes them sleep', 'Adds weight'], 'a': 1},
    ],
    'pet_care': [
      {'q': 'Toxic food for dogs?', 'options': ['Carrots', 'Grapes', 'Rice', 'Peanut Butter'], 'a': 1},
      {'q': 'Sign of heatstroke in dogs?', 'options': ['Wagging tail', 'Excessive panting', 'Sleeping', 'Slow breath'], 'a': 1},
      {'q': 'A cat wagging its tail fast?', 'options': ['Happy', 'Agitated/Annoyed', 'Food', 'Sleepy'], 'a': 1},
      {'q': 'Approaching unknown dog?', 'options': ['Run', 'Sniff hand back', 'Pat head', 'Stare'], 'a': 1},
      {'q': 'Missing pet action?', 'options': ['Wait', 'Search and notify owner', 'Ignore', 'Replace'], 'a': 1},
      {'q': 'Chocolate contains what toxin?', 'options': ['Caffeine', 'Theobromine', 'Sugar', 'Vitamin C'], 'a': 1},
      {'q': 'Cat purring meaning?', 'options': ['Always happy', 'Content or self-soothing', 'Hungry', 'Pain only'], 'a': 1},
      {'q': 'Dog "stiff" body language?', 'options': ['Relaxed', 'Potential aggression/Arousal', 'Sleepy', 'Excited'], 'a': 1},
      {'q': 'Puppy socialization window?', 'options': ['1 year', '3-12 weeks', '2 years', 'Birth only'], 'a': 1},
      {'q': 'Litter box cleaning freq?', 'options': ['Weekly', 'Monthly', 'Daily', 'When full'], 'a': 2},
    ],
    'driver': [
      {'q': 'Flashing yellow light?', 'options': ['Stop', 'Proceed with caution', 'Speed up', 'Yield'], 'a': 1},
      {'q': 'Two-second rule?', 'options': ['Stop sign', 'Following distance', 'Seatbelt', 'Mirrors'], 'a': 1},
      {'q': 'Hydroplaning action?', 'options': ['Brake hard', 'Ease gas/Steer straight', 'Turn sharp', 'Accelerate'], 'a': 1},
      {'q': 'Solid white line?', 'options': ['Change lanes', 'No lane changes', 'Edge', 'Passing'], 'a': 1},
      {'q': 'Parking uphill with curb?', 'options': ['Toward curb', 'Away from curb', 'Straight', 'Neutral'], 'a': 1},
      {'q': 'ABS purpose?', 'options': ['Go faster', 'Prevent wheel lock during braking', 'Save fuel', 'Steering'], 'a': 1},
      {'q': 'Blind spots are...', 'options': ['Sun-blocked', 'Not seen in mirrors', 'Behind car only', 'Internal'], 'a': 1},
      {'q': '4-way stop tie-breaker?', 'options': ['Faster car', 'Car on left', 'Car on right', 'Straight car'], 'a': 2},
      {'q': 'When to use high beams?', 'options': ['Fog', 'City', 'Open road/No oncoming', 'Rain'], 'a': 2},
      {'q': 'Tire pressure check freq?', 'options': ['Annually', 'Monthly', 'Every 5 years', 'When flat'], 'a': 1},
    ],
    'mobile_repair': [
      {'q': 'First step before opening phone?', 'options': ['Remove screen', 'Power off', 'Charge it', 'Call owner'], 'a': 1},
      {'q': 'Solution for water damage?', 'options': ['Hairdryer', 'Rice', 'Open and clean with Isopropyl', 'Turn it on'], 'a': 2},
      {'q': 'ESD stands for?', 'options': ['Easy Screen Delete', 'Electrostatic Discharge', 'Electric System Data', 'Extra Safe Device'], 'a': 1},
      {'q': 'Tool for small screws?', 'options': ['Hammer', 'Precision Screwdriver', 'Drill', 'Pliers'], 'a': 1},
      {'q': 'Why use heat on a phone back?', 'options': ['Kill germs', 'Soften adhesive', 'Expand battery', 'Dry it'], 'a': 1},
      {'q': 'Purpose of digitizer?', 'options': ['Display image', 'Sense touch', 'Store data', 'Audio'], 'a': 1},
      {'q': 'Common reason for "no signal"?', 'options': ['Broken screen', 'Antenna/SIM issues', 'Low battery', 'Volume low'], 'a': 1},
      {'q': 'Lithium battery safety?', 'options': ['Puncture it', 'Keep away from heat/Do not bend', 'Freeze it', 'Wash it'], 'a': 1},
      {'q': 'FPC connector?', 'options': ['Power cord', 'Flexible Printed Circuit', 'Fast Phone Charger', 'Front Port Case'], 'a': 1},
      {'q': 'Bricked phone meaning?', 'options': ['Phone is heavy', 'Software failure makes it unusable', 'Screen is cracked', 'Battery is dead'], 'a': 1},
    ],
    'appliance_repair': [
      {'q': 'Fridge not cooling, first check?', 'options': ['Compressor', 'Power plug/Thermostat', 'Lightbulb', 'Door handle'], 'a': 1},
      {'q': 'Burning smell from dryer?', 'options': ['Lint buildup', 'Water leak', 'Door open', 'Cold air'], 'a': 0},
      {'q': 'Washing machine shaking?', 'options': ['Not plugged', 'Unbalanced load/Uneven legs', 'No soap', 'Too much water'], 'a': 1},
      {'q': 'Safety rule before repair?', 'options': ['Wear gloves', 'Unplug power', 'Call boss', 'Use water'], 'a': 1},
      {'q': 'Microwave sparking?', 'options': ['Door loose', 'Metal inside', 'Old food', 'Low power'], 'a': 1},
      {'q': 'Dishwasher not draining?', 'options': ['No soap', 'Clogged filter/Drain pump', 'Cold water', 'Door open'], 'a': 1},
      {'q': 'Oven not heating?', 'options': ['Light off', 'Heating element/Igniter failure', 'Timer set', 'Door glass'], 'a': 1},
      {'q': 'A Multimeter is used for...', 'options': ['Measuring time', 'Checking electrical continuity', 'Weighing', 'Cleaning'], 'a': 1},
      {'q': 'Vacuum suction loss?', 'options': ['Full bag/Clogged hose', 'New filter', 'Long cord', 'Power on'], 'a': 0},
      {'q': 'AC leaking water inside?', 'options': ['Normal', 'Blocked condensate drain', 'Too cold', 'Filter missing'], 'a': 1},
    ],
    'tv_setup': [
      {'q': 'HDMI cable purpose?', 'options': ['Power only', 'Audio and Video', 'Internet', 'Remote control'], 'a': 1},
      {'q': 'Aspect ratio for Wide Screen?', 'options': ['4:3', '16:9', '1:1', '21:9'], 'a': 1},
      {'q': 'Wall mount safety?', 'options': ['Use tape', 'Mount to studs', 'Glue it', 'Lean on it'], 'a': 1},
      {'q': 'OLED vs LED?', 'options': ['OLED uses more power', 'OLED has self-lighting pixels', 'LED is thinner', 'No difference'], 'a': 1},
      {'q': 'TV Remote not working?', 'options': ['Change TV', 'Check batteries/Obstructions', 'Clean screen', 'Turn off lights'], 'a': 1},
      {'q': '4K resolution?', 'options': ['1080p', '3840 x 2160', '720p', '400p'], 'a': 1},
      {'q': 'ARC on HDMI stands for?', 'options': ['Auto Remote Control', 'Audio Return Channel', 'Active Run Connection', 'Aerial Radio'], 'a': 1},
      {'q': 'Motion Blur fix?', 'options': ['Higher Refresh Rate', 'Lower brightness', 'Bigger screen', 'Mute audio'], 'a': 0},
      {'q': 'Smart TV needs?', 'options': ['VCR', 'Internet Connection', 'Antenna only', 'Cable box only'], 'a': 1},
      {'q': 'Best viewing angle?', 'options': ['Side', 'Eye level/Center', 'Floor', 'Ceiling'], 'a': 1},
    ],
    'cctv': [
      {'q': 'DVR vs NVR?', 'options': ['DVR is digital', 'NVR for IP cameras', 'DVR is faster', 'No difference'], 'a': 1},
      {'q': 'Night vision technology?', 'options': ['Lamps', 'Infrared (IR)', 'Flashlight', 'Sunlight'], 'a': 1},
      {'q': 'BNC connector usage?', 'options': ['Power', 'Coaxial Video', 'Internet', 'Audio'], 'a': 1},
      {'q': 'Camera with 360 rotation?', 'options': ['Bullet', 'Dome', 'PTZ', 'Box'], 'a': 2},
      {'q': 'PoE stands for?', 'options': ['Power over Ethernet', 'Point of Entry', 'Position of Engine', 'Port of Exit'], 'a': 0},
      {'q': 'Field of View (FOV)?', 'options': ['Camera weight', 'Area visible through lens', 'Storage size', 'Color depth'], 'a': 1},
      {'q': 'Frame Rate (FPS) purpose?', 'options': ['Brightness', 'Smoothness of video', 'Distance', 'Zoom'], 'a': 1},
      {'q': 'Bullet camera best use?', 'options': ['Hidden', 'Outdoor/Long distance', 'Ceiling indoor', 'Desktop'], 'a': 1},
      {'q': 'Storage for CCTV?', 'options': ['RAM', 'Hard Drive (HDD)', 'CD', 'Paper'], 'a': 1},
      {'q': 'WDR stands for?', 'options': ['Wide Dynamic Range', 'Wireless Data Receiver', 'Water Drain Route', 'Wall Door Record'], 'a': 0},
    ],
    'wifi': [
      {'q': 'Frequency with better range?', 'options': ['5GHz', '2.4GHz', '6GHz', '10GHz'], 'a': 1},
      {'q': 'SSID is another name for?', 'options': ['Password', 'Network Name', 'Router brand', 'Cable type'], 'a': 1},
      {'q': 'Router placement?', 'options': ['Floor', 'Central open area', 'Inside metal box', 'Bathroom'], 'a': 1},
      {'q': 'Fastest Wi-Fi standard?', 'options': ['Wi-Fi 4', 'Wi-Fi 6', 'Wi-Fi 1', 'Dial-up'], 'a': 1},
      {'q': 'Resetting router password?', 'options': ['Buy new', 'Factory Reset button', 'Change Wi-Fi', 'Call ISP'], 'a': 1},
      {'q': 'What is a Repeater?', 'options': ['New internet', 'Device to extend signal range', 'Phone charger', 'Monitor'], 'a': 1},
      {'q': 'Secure Wi-Fi encryption?', 'options': ['WEP', 'WPA3', 'Open', 'No password'], 'a': 1},
      {'q': 'Ethernet cable (LAN)?', 'options': ['Wireless', 'Wired connection', 'Battery', 'Screen'], 'a': 1},
      {'q': 'Ping measures?', 'options': ['Speed', 'Latency/Delay', 'Weight', 'Distance'], 'a': 1},
      {'q': 'IP Address?', 'options': ['Street address', 'Unique identifier on network', 'Email', 'Password'], 'a': 1},
    ],
    'home_automation': [
      {'q': 'Protocol for smart devices?', 'options': ['Zigbee/Z-Wave', 'HTTP', 'Bluetooth only', 'SMS'], 'a': 0},
      {'q': 'Smart hub purpose?', 'options': ['Charging', 'Connecting/Controlling devices', 'Internet provider', 'Speaker'], 'a': 1},
      {'q': 'Smart bulb advantage?', 'options': ['Brighter', 'Dimming/Remote control', 'Cheaper', 'Bigger'], 'a': 1},
      {'q': 'What is Geofencing?', 'options': ['Physical fence', 'Location-based automation', 'Internet wall', 'Gardening'], 'a': 1},
      {'q': 'Smart locks need?', 'options': ['Keys', 'Battery/Wi-Fi connection', 'Wires', 'Oil'], 'a': 1},
      {'q': 'Scenes in automation?', 'options': ['Movies', 'Pre-set group of actions', 'Pictures', 'Rooms'], 'a': 1},
      {'q': 'Smart Thermostat benefit?', 'options': ['Cooks food', 'Energy savings/Remote temp control', 'Bigger TV', 'Music'], 'a': 1},
      {'q': 'Voice assistant example?', 'options': ['Chrome', 'Alexa/Google Assistant', 'Windows', 'Facebook'], 'a': 1},
      {'q': 'Sensor to detect leaks?', 'options': ['Motion', 'Water/Flood sensor', 'Smoke', 'Contact'], 'a': 1},
      {'q': 'IFTTT stands for?', 'options': ['If This Then That', 'Instant Fast Time', 'Internal File Transmit', 'In Fact True'], 'a': 0},
    ],
    'solar_installers': [
      {'q': 'Best panel direction (Northern Hemisphere)?', 'options': ['North', 'South', 'East', 'West'], 'a': 1},
      {'q': 'PV stands for?', 'options': ['Power Volt', 'Photovoltaic', 'Private Voltage', 'Point Valve'], 'a': 1},
      {'q': 'Inverter purpose?', 'options': ['Charge battery', 'Convert DC to AC', 'Clean panels', 'Measure heat'], 'a': 1},
      {'q': 'Panel maintenance?', 'options': ['Waxing', 'Regular cleaning/Dust removal', 'Painting', 'Changing glass'], 'a': 1},
      {'q': 'Solar battery function?', 'options': ['Make sun brighter', 'Store energy for night', 'Cool panels', 'Increase voltage'], 'a': 1},
      {'q': 'Grid-tied system?', 'options': ['Connected to utility grid', 'Uses no wires', 'Only for camping', 'No panels'], 'a': 0},
      {'q': 'Solar Charge Controller?', 'options': ['Increases sun', 'Prevents battery overcharging', 'Turns off TV', 'Remote'], 'a': 1},
      {'q': 'Net Metering?', 'options': ['Selling excess power back to grid', 'Measuring sun', 'Cleaning tool', 'Battery life'], 'a': 0},
      {'q': 'Shadow effect?', 'options': ['Better cooling', 'Significant power reduction', 'Makes panels blue', 'None'], 'a': 1},
      {'q': 'Kilowatt hour (kWh)?', 'options': ['Weight', 'Unit of energy consumption', 'Speed', 'Heat'], 'a': 1},
    ],
    'tutor': [
      {'q': 'Best way to check student understanding?', 'options': ['Assume they know', 'Ask questions/Apply concepts', 'Talk faster', 'Give answers'], 'a': 1},
      {'q': 'Learning style focusing on pictures?', 'options': ['Auditory', 'Visual', 'Kinesthetic', 'Reading'], 'a': 1},
      {'q': 'Tutor\'s role?', 'options': ['Do homework', 'Guide and facilitate learning', 'Replace teachers', 'Grade exams'], 'a': 1},
      {'q': 'Positive reinforcement?', 'options': ['Giving extra work', 'Praising effort/progress', 'Ignoring mistakes', 'Testing hourly'], 'a': 1},
      {'q': 'Handling a struggling student?', 'options': ['Stop tutoring', 'Identify gaps and change method', 'Blame student', 'Repeat same way'], 'a': 1},
      {'q': 'Lesson plan importance?', 'options': ['Structure and goals', 'Just for show', 'Takes too much time', 'Optional'], 'a': 0},
      {'q': 'Active listening?', 'options': ['Interrupting', 'Summarizing/Paying attention', 'Doing other tasks', 'Silence'], 'a': 1},
      {'q': 'Managing distractions?', 'options': ['Join in', 'Set clear environment/rules', 'Ignore it', 'End lesson'], 'a': 1},
      {'q': 'Student motivation?', 'options': ['Fear', 'Relating topics to interests', 'Boredom', 'Heavy testing'], 'a': 1},
      {'q': 'Constructive feedback?', 'options': ['"You are bad"', 'Specific areas to improve + Praise', 'Silence', 'Correcting every word'], 'a': 1},
    ],
    'yoga_trainer': [
      {'q': 'Focus of Pranayama?', 'options': ['Stretching', 'Breath control', 'Balance', 'Strength'], 'a': 1},
      {'q': 'Common beginner pose?', 'options': ['Handstand', 'Tadasana (Mountain Pose)', 'Lotus', 'Split'], 'a': 1},
      {'q': 'Yoga benefit?', 'options': ['Flexibility/Stress reduction', 'Extreme hunger', 'Running speed', 'Confusion'], 'a': 0},
      {'q': 'Important for safety?', 'options': ['Push through pain', 'Proper alignment/Listen to body', 'Hold breath', 'Fast movements'], 'a': 1},
      {'q': 'Purpose of Savasana?', 'options': ['Exercise', 'Relaxation/Integration', 'Strength', 'Warm-up'], 'a': 1},
      {'q': '"Namaste" meaning?', 'options': ['Goodbye', 'The light in me honors the light in you', 'Start exercise', 'Happy'], 'a': 1},
      {'q': 'Yoga mat purpose?', 'options': ['Sleep', 'Grip and cushioning', 'Fashion', 'Heat'], 'a': 1},
      {'q': 'Sun Salutation (Surya Namaskar)?', 'options': ['Evening pose', 'Dynamic sequence of poses', 'A breathing technique', 'Meditation only'], 'a': 1},
      {'q': 'Core focus of yoga?', 'options': ['Mind-Body connection', 'Only physical', 'Weight lifting', 'Talking'], 'a': 0},
      {'q': 'Yoga for seniors focus?', 'options': ['Running', 'Gentle mobility/Balance', 'Heavy lifting', 'Speed'], 'a': 1},
    ],
    'music_teacher': [
      {'q': 'What is Tempo?', 'options': ['Loudness', 'Speed of music', 'Tone quality', 'Instrument name'], 'a': 1},
      {'q': 'Standard 5 lines for music notes?', 'options': ['Stave/Staff', 'Measure', 'Scale', 'Rhythm'], 'a': 0},
      {'q': 'Instrument with keys?', 'options': ['Violin', 'Piano', 'Flute', 'Drum'], 'a': 1},
      {'q': 'What is a Sharp (#)?', 'options': ['Lower pitch', 'Higher pitch', 'Loud sound', 'Ending'], 'a': 1},
      {'q': 'Teaching beginner rhythm?', 'options': ['Metronome/Clapping', 'Playing fast', 'Skipping notes', 'Silent reading'], 'a': 0},
      {'q': 'A Chord is...', 'options': ['One note', 'Multiple notes played together', 'A string', 'Instrument case'], 'a': 1},
      {'q': 'Major vs Minor scale?', 'options': ['Happy vs Sad/Serious sound', 'Loud vs Quiet', 'Fast vs Slow', 'Big vs Small'], 'a': 0},
      {'q': 'What is Dynamics?', 'options': ['Speed', 'Volume variation (Loud/Soft)', 'Note height', 'Instrument type'], 'a': 1},
      {'q': 'Ear training?', 'options': ['Cleaning ears', 'Recognizing pitches/intervals by sound', 'Loud music', 'Listening to radio'], 'a': 1},
      {'q': 'Practicing importance?', 'options': ['Once a month', 'Daily/Consistent routine', 'Only during lessons', 'Not needed'], 'a': 1},
    ],
    'event_assistant': [
      {'q': 'Priority at event start?', 'options': ['Eating', 'Guest registration/Check-in', 'Cleaning up', 'Sitting down'], 'a': 1},
      {'q': 'Essential skill?', 'options': ['Running', 'Communication/Organization', 'Singing', 'Cooking'], 'a': 1},
      {'q': 'Handling a guest complaint?', 'options': ['Ignore', 'Listen and resolve/report', 'Argue', 'Walk away'], 'a': 1},
      {'q': 'Crowd control means?', 'options': ['Yelling', 'Managing guest flow safely', 'Locking doors', 'Selling tickets'], 'a': 1},
      {'q': 'Setup checklist item?', 'options': ['Personal phone', 'AV equipment/Signage', 'Lunch menu', 'Seating order'], 'a': 1},
      {'q': 'Professional attire?', 'options': ['Pyjamas', 'Standardized/Event-appropriate uniform', 'Swimwear', 'Neon colors'], 'a': 1},
      {'q': 'Time management?', 'options': ['Being late', 'Punctuality/Following schedule', 'Ignoring clock', 'Taking long breaks'], 'a': 1},
      {'q': 'Crisis at event?', 'options': ['Panic', 'Stay calm and notify lead', 'Hide', 'Blame guests'], 'a': 1},
      {'q': 'Radio etiquette?', 'options': ['Chatting', 'Clear/Brief communication', 'Music', 'No use'], 'a': 1},
      {'q': 'Post-event task?', 'options': ['Leave immediately', 'Cleanup and debrief', 'Party', 'Sleep'], 'a': 1},
    ],
    'errand_helper': [
      {'q': 'Grocery shopping priority?', 'options': ['Buy snacks', 'Check expiration dates', 'Buy heaviest first', 'Ignore list'], 'a': 1},
      {'q': 'Safety with personal items?', 'options': ['Leave in car', 'Secure handling/Verification', 'Give to strangers', 'Throw away'], 'a': 1},
      {'q': 'Communicating delay?', 'options': ['Don\'t call', 'Notify client immediately', 'Cancel errand', 'Lie about time'], 'a': 1},
      {'q': 'Organizing multiple tasks?', 'options': ['Do randomly', 'Route planning/Priority list', 'One at a time slowly', 'Forget half'], 'a': 1},
      {'q': 'Task completion?', 'options': ['Leave items at door', 'Verify with client/Get proof', 'Call it done', 'Give to neighbor'], 'a': 1},
      {'q': 'Errand for elderly?', 'options': ['Rush them', 'Patience and clear instruction', 'Ignore needs', 'Walk fast'], 'a': 1},
      {'q': 'Handling money?', 'options': ['Lose receipts', 'Keep accurate track/Provide change', 'Spend it', 'No tracking'], 'a': 1},
      {'q': 'Product substitution?', 'options': ['Guess', 'Ask client for preference', 'Buy anything', 'Don\'t buy'], 'a': 1},
      {'q': 'Confidentiality?', 'options': ['Tell neighbors', 'Respect client privacy', 'Post on social media', 'Read mail'], 'a': 1},
      {'q': 'Reliability?', 'options': ['Do it tomorrow', 'Complete on time as promised', 'Skip parts', 'Cancel last minute'], 'a': 1},
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _answerQuestion(int selectedIndex) {
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final questions = _allQuestions[currentSkill] ?? [];

    if (selectedIndex == questions[_currentQuestionIndex]['a']) {
      _score++;
    }

    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
      if (_score >= (questions.length * 0.7).ceil()) {
        _passedSkills.add(currentSkill);
      }

      _nextSkill();
    }
  }

  void _nextSkill() {
    if (_currentSkillIndex < widget.selectedSkills.length - 1) {
      setState(() {
        _currentSkillIndex++;
        _currentQuestionIndex = 0;
        _score = 0;
        _animationController.reset();
        _animationController.forward();
      });
    } else {
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
    final currentSkill = widget.selectedSkills[_currentSkillIndex];
    final questions = _allQuestions[currentSkill] ?? [];

    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BilingualText(textKey: 'no_questions_for', args: [currentSkill.replaceAll('_', ' ')]),
              ElevatedButton(
                onPressed: _nextSkill,
                child: const BilingualText(textKey: 'back'),
              ),
            ],
          ),
        ),
      );
    }

    final question = questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: BilingualText(textKey: currentSkill, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BilingualText(
                  textKey: 'question_progress',
                  args: [(_currentQuestionIndex + 1).toString(), questions.length.toString()],
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        question['q'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      ...List.generate(
                        (question['options'] as List).length,
                            (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton(
                            onPressed: () => _answerQuestion(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textColor,
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              question['options'][index] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
