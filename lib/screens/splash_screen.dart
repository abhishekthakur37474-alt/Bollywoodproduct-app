import 'dart:async';
import 'package:flutter/material.dart';
import 'movie_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MoviePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xffD4AF37), // gold accent
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffD4AF37).withOpacity(0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Image.asset(
                "assets/images/logo.jpeg",
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              "Bollywood Product",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xffD4AF37), // gold
              ),
            ),

            const SizedBox(height: 14),

            Text(
              "Latest Films • Trailers • Details",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation(Color(0xffD4AF37)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
