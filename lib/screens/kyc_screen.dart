import 'package:flutter/material.dart';
import '../services/kyc_service.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({Key? key}) : super(key: key);

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  final KYCService _kycService = KYCService();
  String? extractedText;
  bool loading = false;

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
      appBar: AppBar(title: const Text('KYC Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _scanDocument,
                      child: const Text('Scan ID Document'),
                    ),
                    const SizedBox(height: 24),
                    extractedText == null
                        ? const Text('No document scanned yet.')
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Text(extractedText!),
                            ),
                          ),
                  ],
                ),
        ),
      ),
    );
  }
}
