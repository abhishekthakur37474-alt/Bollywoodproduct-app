import 'package:flutter/material.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        title: const Text("Terms of Use"),
        backgroundColor: Colors.black,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            "Bollywood Product is operated by BPBB Digital LLP.\n\n"
                "Bollywood Product is an informational film database application.\n\n"
                "Users must use the app only for lawful purposes.\n\n"
                "The app provides film information collected from publicly available sources.\n\n"
                "Users must access OTT platforms through official apps.\n\n"
                "Unauthorized copying or misuse is prohibited.\n\n"
                "Users are responsible for account activity.\n\n"
                "App owners are not responsible for damages.\n\n"
                "Features may change without notice.",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
      ),
    );
  }
}
