import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Returns a bilingual string in the format "English (Telugu)" for a given localization key.
String btr(BuildContext context, String key) {
  final translations = EasyLocalization.of(context)!.translations;
  final englishText = translations.get(key, locale: 'en') ?? key;
  final teluguText = translations.get(key, locale: 'te') ?? key;

  if (englishText == key && teluguText == key) {
    // If the key is not found in both languages, return the key itself.
    return key;
  }
  
  if (englishText == teluguText || teluguText == key || teluguText.isEmpty) {
      // If translations are the same or telugu is missing, return only english
      return englishText;
  }
  
  if (englishText == key || englishText.isEmpty) {
      // If english is missing, return only telugu
      return teluguText;
  }

  return '$englishText ($teluguText)';
}
