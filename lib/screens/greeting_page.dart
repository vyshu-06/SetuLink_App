import 'package:flutter/material.dart';
import 'package:setulink_app/screens/login_screen.dart';
import 'package:setulink_app/screens/register_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class GreetingPage extends StatelessWidget {
  const GreetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo
                Image.asset(
                  'assets/images/app_logo.png',
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.link, size: 100, color: Colors.teal),
                ),
                const SizedBox(height: 20),

                // 2. Bilingual Title
                const BilingualText(
                  textKey: 'setulink_title',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 3. Bilingual Tagline
                BilingualText(
                  textKey: 'tagline',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.5, // Better line spacing
                  ),
                ),
                const SizedBox(height: 50),

                // 4. User (Citizen) Button - Wide & Teal
                SizedBox(
                  width: double.infinity,
                  height: 55, // Fixed height for consistency
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const LoginScreen(initialRole: 'citizen'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688), // Teal color
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Slightly rounded corners like image
                      ),
                    ),
                    child: const BilingualText(
                      textKey: 'user_button',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Craftizen Button - Wide & Orange
                SizedBox(
                  width: double.infinity,
                  height: 55, // Fixed height
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const LoginScreen(initialRole: 'craftizen'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722), // Deep Orange
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const BilingualText(
                      textKey: 'craftizen_button',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 6. Admin Panel Text Link (Subtle)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const LoginScreen(initialRole: 'admin'),
                      ),
                    );
                  },
                  child: const BilingualText(
                    textKey: 'admin_panel_button',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 60), // Spacing before bottom text

                // 7. Register Now Footer
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const BilingualText(
                      textKey: 'new_to_app_text',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const BilingualText(
                        textKey: 'register_now_button',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
