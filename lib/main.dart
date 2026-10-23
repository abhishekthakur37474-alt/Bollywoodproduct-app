import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'widgets/promo_popup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("🟡 [MAIN] Initializing Firebase");
  await Firebase.initializeApp();
  print("🟢 [MAIN] Firebase initialized");

  // 🔥 INIT FCM AFTER Firebase
  await FcmService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      navigatorObservers: [PromoPopupRouteObserver()],
      builder: (context, child) =>
          PromoBubbleLayer(child: child ?? const SizedBox.shrink()),
      title: "Bollywood Product",
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
