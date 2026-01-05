import 'package:flutter/material.dart';
import 'package:setulink_app/screens/login_screen.dart';
import 'package:setulink_app/screens/register_screen.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';
import 'package:setulink_app/theme/app_colors.dart';

class GreetingPage extends StatefulWidget {
  const GreetingPage({super.key});

  @override
  State<GreetingPage> createState() => _GreetingPageState();
}

class _GreetingPageState extends State<GreetingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        height: 100,
                        width: 100,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.link, size: 100, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      const BilingualText(
                        textKey: 'setulink_title',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      BilingualText(
                        textKey: 'tagline',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withOpacity(0.9), height: 1.5),
                      ),
                      const SizedBox(height: 50),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen(initialRole: 'citizen'))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryColor,
                          ),
                          child: const BilingualText(textKey: 'user_button', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen(initialRole: 'craftizen'))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentColor,
                            foregroundColor: Colors.black,
                          ),
                          child: const BilingualText(textKey: 'craftizen_button', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen(initialRole: 'admin'))),
                        child: const BilingualText(textKey: 'admin_panel_button', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 60),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const BilingualText(textKey: 'new_to_app_text', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                            child: const BilingualText(textKey: 'register_now_button', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
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
