import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/home_service.dart';
import '../widgets/bottom_nav.dart';

class HomeLoaderScreen extends StatefulWidget {
  const HomeLoaderScreen({super.key});

  @override
  State<HomeLoaderScreen> createState() => _HomeLoaderScreenState();
}

class _HomeLoaderScreenState extends State<HomeLoaderScreen>
    with SingleTickerProviderStateMixin {

  int msgIndex = 0;

  final messages = [
    "Showing you the best choice...",
    "Finding latest Bollywood updates...",
    "Curating movies just for you...",
    "Almost ready 🍿",
    "Loading premium experience..."
  ];

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _startMessages();
    _load();
  }

  void _startMessages() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        msgIndex = (msgIndex + 1) % messages.length;
      });
    });
  }

  Future<void> _load() async {
    print("🟡 [LOADER] Loading home APIs");

    await HomeService.loadAllHomeData();

    print("🟢 [LOADER] Done → Opening Home");

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
                border: Border.all(
                  color: const Color(0xffD4AF37),
                  width: 2.5,
                ),
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
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
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
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
