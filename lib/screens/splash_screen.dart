// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../widgets/bottom_nav.dart';
// import '../screens/login_screen.dart';
// import '../screens/profile_screen.dart';
// import '../utils/home_service.dart';
// import 'home_loader_screen.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }
//
//
//
//   Future<void> _init() async {
//     print("🟡 [SPLASH] Showing splash");
//
//     await Future.delayed(const Duration(milliseconds: 700));
//
//     print("🟢 [SPLASH] Redirecting to loader");
//
//     _go(const HomeLoaderScreen());
//   }
//
//
//
//
//   void _go(Widget page) {
//     if (!mounted) return;
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => page),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: const Color(0xff0F0F0F),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             /// 🔥 GOLDEN RING + CIRCULAR LOGO
//             Container(
//               width: size.width * 0.42,
//               height: size.width * 0.42,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: const Color(0xffD4AF37),
//                   width: 2.4,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xffD4AF37).withOpacity(0.35),
//                     blurRadius: 60,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(16),
//               child: ClipOval(
//                 child: Image.asset(
//                   "assets/images/logo.jpeg",
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 26),
//
//             /// 🏆 APP NAME
//             const Text(
//               "Bollywood Product",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xffD4AF37),
//                 letterSpacing: 0.4,
//               ),
//             ),
//
//             const SizedBox(height: 6),
//
//             /// ✨ TAGLINE
//             const Text(
//               " · Your Film Information hub · ",
//               style: TextStyle(
//                 color: Colors.white60,
//                 fontSize: 14,
//                 letterSpacing: 0.3,
//               ),
//             ),
//
//             const SizedBox(height: 34),
//
//             /// ⏳ LOADER
//             const SizedBox(
//               width: 22,
//               height: 22,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2.2,
//                 color: Color(0xffD4AF37),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../utils/home_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  int msgIndex = 0;

  final messages = [
    "Showing you the best choice...",
    "Finding latest Bollywood updates...",
    "Curating movies just for you...",
    "Almost ready 🍿",
    "Loading premium experience...",
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startMessages();
    _init();
  }

  void _startMessages() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        msgIndex = (msgIndex + 1) % messages.length;
      });
    });
  }

  Future<void> _init() async {
    print("🟡 [SPLASH] Showing splash and loading data");

    /// 🔥 Load all data during splash
    await HomeService.loadAllHomeData();

    print("🟢 [SPLASH] Data loaded → Opening Home");

    _timer.cancel();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNav()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔥 PREMIUM LOGO
            Container(
              width: size.width * 0.36,
              height: size.width * 0.36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffD4AF37), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffD4AF37).withOpacity(0.35),
                    blurRadius: 60,
                    spreadRadius: 3,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/logo.jpeg",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// 🎬 APP NAME
            const Text(
              "Bollywood Product",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xffD4AF37),
              ),
            ),

            const SizedBox(height: 10),

            /// ✨ ROTATING MESSAGE
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                messages[msgIndex],
                key: ValueKey(msgIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            const SizedBox(height: 34),

            /// ⏳ PREMIUM LOADER
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: Color(0xffD4AF37),
              ),
            ),

            const SizedBox(height: 22),

            /// 💡 TRUST MESSAGE
            const Text(
              "Please wait, we are preparing your experience",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
