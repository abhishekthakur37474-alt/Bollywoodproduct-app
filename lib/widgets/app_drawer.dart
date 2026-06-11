import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bollywood/screens/terms_view.dart';
import 'package:bollywood/screens/privacy_view.dart';
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
