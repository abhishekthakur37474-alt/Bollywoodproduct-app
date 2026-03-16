import 'package:flutter/material.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: Colors.black,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            "Bollywood Product respects user privacy.\n\n"
                "Google login collects only basic data.\n\n"
                "No sensitive data is collected.\n\n"
                "Data used for authentication and improvement.\n\n"
                "We do not sell user data.\n\n"
                "Third-party platforms have their own policies.",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
      ),
    );
  }
}
