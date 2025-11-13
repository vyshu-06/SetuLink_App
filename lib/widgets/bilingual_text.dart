import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class BilingualText extends StatefulWidget {
  final String textKey;
  final TextStyle? style;

  const BilingualText({Key? key, required this.textKey, this.style}) : super(key: key);

  @override
  _BilingualTextState createState() => _BilingualTextState();
}

class _BilingualTextState extends State<BilingualText> {
  Future<Map<String, String>>? _translations;

  @override
  void initState() {
    super.initState();
    _translations = _loadTranslations();
  }

  Future<Map<String, String>> _loadTranslations() async {
    try {
      final enJson = await rootBundle.loadString('assets/translations/en.json');
      final teJson = await rootBundle.loadString('assets/translations/te.json');

      final Map<String, dynamic> enMap = json.decode(enJson);
      final Map<String, dynamic> teMap = json.decode(teJson);

      final enText = enMap[widget.textKey] as String? ?? widget.textKey;
      final teText = teMap[widget.textKey] as String? ?? widget.textKey;

      return {'en': enText, 'te': teText};
    } catch (e) {
      // If loading fails, return the key itself
      return {'en': widget.textKey, 'te': widget.textKey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _translations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final englishText = snapshot.data!['en']!;
          final teluguText = snapshot.data!['te']!;
          final currentLocale = context.locale;

          // Determine the order based on the current app locale
          final bilingualText = currentLocale.languageCode == 'te'
              ? '$teluguText ($englishText)'
              : '$englishText ($teluguText)';

          return Text(
            bilingualText,
            style: widget.style,
            textAlign: TextAlign.center, // Center align the text
          );
        }
        
        // Show a placeholder or the key while loading
        return Text(widget.textKey, style: widget.style, textAlign: TextAlign.center,);
      },
    );
  }
}