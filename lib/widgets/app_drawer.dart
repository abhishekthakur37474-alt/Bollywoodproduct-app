import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bollywood/screens/terms_view.dart';
import 'package:bollywood/screens/privacy_view.dart';
import 'package:bollywood/screens/bollywood_quiz_screen.dart';
// import 'package:bollywood/screens/account_page.dart'; // Temporarily hidden

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "User";

    return Drawer(
      backgroundColor: const Color(0xff111111),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 👋 HELLO USER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Hello, $name",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const Divider(color: Colors.white24),

            /// ACCOUNT (temporarily hidden)
            // ListTile(
            //   leading: const Icon(Icons.person, color: Colors.white),
            //   title: const Text("Account",
            //       style: TextStyle(color: Colors.white)),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const AccountPage()),
            //     );

            //   },
            // ),

            /// 🎯 BOLLYWOOD QUIZ
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedBrain01,
                size: 24.0,
                color: Color(0xffD4AF37),
                strokeWidth: 1.5,
              ),
              title: const Text(
                "Bollywood Quiz",
                style: TextStyle(
                  color: Color(0xffD4AF37),
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xffD4AF37).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffD4AF37), width: 0.8),
                ),
                child: const Text(
                  "Coming Soon",
                  style: TextStyle(
                    color: Color(0xffD4AF37),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BollywoodQuizScreen()),
                );
              },
            ),

            /// TERMS
            ListTile(
              leading: const Icon(Icons.description, color: Colors.white),
              title: const Text(
                "Terms of App",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsView()),
                );
              },
            ),

            /// PRIVACY
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.white),
              title: const Text(
                "Privacy Policy",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
