import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool acceptedPolicy = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔰 LOGO
            Image.asset(
              "assets/images/logo.jpeg",
              width: size.width * 0.32,
            ),

            const SizedBox(height: 28),

            /// 🏆 TITLE
            const Text(
              "Welcome to Bollywood Product",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Sign in to continue",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 40),

            /// 🔐 GOOGLE LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (!acceptedPolicy) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please accept Privacy Policy"),
                      ),
                    );
                    return;
                  }

                  final user = await AuthService.signInWithGoogle();
                  if (user == null) return;

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplashScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Continue with Google",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ✅ PRIVACY POLICY ACCEPT
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: acceptedPolicy,
                  activeColor: const Color(0xffD4AF37),
                  onChanged: (v) {
                    setState(() {
                      acceptedPolicy = v ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPrivacyPolicy(context),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        "I agree to the Privacy Policy and data usage terms.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ PRIVACY POLICY MODAL
  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: controller,
                children: const [
                  Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    "Bollywood Product respects user privacy and is committed to protecting personal information.\n\n"
                        "Users may sign in using Google authentication. Basic profile details such as name and email are collected only for login and app functionality.\n\n"
                        "No sensitive data such as passwords or payment information is collected.\n\n"
                        "The app may collect limited technical data such as device and performance analytics.\n\n"
                        "Collected data is used for authentication, app improvement and personalisation.\n\n"
                        "Bollywood Product does not sell or share personal information.\n\n"
                        "Third-party platforms such as YouTube and OTT services operate under their own policies.\n\n"
                        "Reasonable security measures are used to protect user data.\n\n"
                        "This policy may be updated from time to time.\n\n"
                        "Bollywood Product is operated by BPBB Digital LLP.",
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
