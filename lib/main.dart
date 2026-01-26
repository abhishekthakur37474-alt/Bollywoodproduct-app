import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'movie_page.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Bollywood Films",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xff0F0F0F),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xffD4AF37),
          secondary: Color(0xffBB9F53),
        ),
      ),
      home: const SplashScreen(),

    );
  }
}
