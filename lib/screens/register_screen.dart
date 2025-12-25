import 'package:flutter/material.dart';
import 'package:setulink_app/screens/citizen_register_screen.dart';
import 'package:setulink_app/screens/craftizen_register_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CitizenRegisterScreen()),
                  );
                },
                child: const Text('Register as a Citizen'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CraftizenRegisterScreen()),
                  );
                },
                child: const Text('Register as a Craftizen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
