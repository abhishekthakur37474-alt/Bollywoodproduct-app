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


import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'home_loader_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print("🟡 [SPLASH] Showing splash");

    /// 🔥 5 second splash (fast, no API here)
    await Future.delayed(const Duration(seconds: 5));

    print("🟢 [SPLASH] Redirecting to loader");

    _go(const HomeLoaderScreen());
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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
            Container(
              width: size.width * 0.42,
              height: size.width * 0.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xffD4AF37),
                  width: 2.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffD4AF37).withOpacity(0.35),
                    blurRadius: 60,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/logo.jpeg",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              "Bollywood Product",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xffD4AF37),
                letterSpacing: 0.4,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              " · Your Film Information hub · ",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 34),

            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xffD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
