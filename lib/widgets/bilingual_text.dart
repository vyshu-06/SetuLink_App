import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static Map<String, dynamic>? _enMap;

  /// Call this in main() to ensure English translations are available immediately
  static Future<void> initEn() async {
    if (_enMap != null) return;
    try {
      final String response = await rootBundle.loadString('assets/translations/en.json');
      _enMap = json.decode(response);
    } catch (e) {
      debugPrint('Error loading en.json for bilingual transcription: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      toBilingual(context, textKey, args: args, namedArgs: namedArgs),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Static helper to get a bilingual string: English (OtherLanguage)
  static String toBilingual(BuildContext context, String key, {List<String>? args, Map<String, String>? namedArgs}) {
    // 1. Get translation for the CURRENT locale (e.g., Telugu)
    String currentText = tr(key, args: args, namedArgs: namedArgs);
    
    // 2. If the current language IS English, just return English text
    if (context.locale.languageCode == 'en') {
      return currentText;
    }

    // 3. Get the English text from our cached map
    String englishText = _enMap?[key] ?? key;
    
    // Process arguments for English text if they exist
    if (_enMap != null && _enMap!.containsKey(key)) {
      if (args != null) {
        for (var arg in args) {
          englishText = englishText.replaceFirst('{}', arg);
        }
      }
      if (namedArgs != null) {
        namedArgs.forEach((k, v) {
          englishText = englishText.replaceAll('{$k}', v);
        });
      }
    }

    // 4. Return combined format: English (OtherLanguage)
    return "$englishText ($currentText)";
  }
}
