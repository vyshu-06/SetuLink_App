import 'package:flutter/material.dart';
import 'package:setulink_app/services/kyc_service.dart';
import 'package:setulink_app/theme/app_colors.dart';
import 'package:setulink_app/widgets/bilingual_text.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({Key? key}) : super(key: key);

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> with SingleTickerProviderStateMixin {
  final KYCService _kycService = KYCService();
  String? extractedText;
  bool loading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  _scanDocument() async {
    setState(() => loading = true);
    final text = await _kycService.pickAndScanIDDocument();
    setState(() {
      extractedText = text;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const BilingualText(textKey: 'kyc_verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryColor, AppColors.accentColor.withOpacity(0.8)],
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BilingualText(textKey: 'verify_your_identity', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    const BilingualText(textKey: 'kyc_instructions', style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 50),
                    if (loading)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt, size: 24),
                        label: const BilingualText(textKey: 'scan_id_document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _scanDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (extractedText != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const BilingualText(textKey: 'extracted_text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                              const SizedBox(height: 12),
                              Text(extractedText!, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
