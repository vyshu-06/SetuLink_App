import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BilingualText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final List<String>? args;
  final Map<String, String>? namedArgs;

  const BilingualText({
    required this.textKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.args,
    this.namedArgs,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Current translation based on app's locale (e.g., Telugu or Hindi)
    String currentText = tr(textKey, args: args, namedArgs: namedArgs);
    
    // Attempt to get English specifically. 
    // Format: English (Telugu)
    String englishText = tr(textKey); // Default fallback is English if key is English or fallback is set
    
    // If the current language is NOT English, we show bilingual: English (Telugu)
    if (context.locale.languageCode != 'en') {
      return Text(
        "$englishText ($currentText)",
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // If English, just show English
    return Text(
      currentText,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
