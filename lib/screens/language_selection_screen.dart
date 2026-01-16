import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/screens/greeting_page.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.translate,
                size: 80,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Select Preferred 2nd Language',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This will show translations alongside English throughout the app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _LanguageButton(
                title: 'Hindi (हिंदी)',
                locale: const Locale('hi'),
                onTap: () => _selectLanguage(context, const Locale('hi')),
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                title: 'Telugu (తెలుగు)',
                locale: const Locale('te'),
                onTap: () => _selectLanguage(context, const Locale('te')),
              ),
              const SizedBox(height: 16),
              _LanguageButton(
                title: 'English Only',
                locale: const Locale('en'),
                onTap: () => _selectLanguage(context, const Locale('en')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(BuildContext context, Locale locale) async {
    await context.setLocale(locale);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const GreetingPage()),
      );
    }
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final Locale locale;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.title,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
