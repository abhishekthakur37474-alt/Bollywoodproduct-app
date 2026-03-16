import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/ott_movies_page.dart';
import '../screens/trailers_page.dart';
import '../screens/account_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;

  final pages = const [
    HomePage(),        // 🏠 Home (Latest + Upcoming + Full)
    OttMoviesPage(),   // 📺 OTT (unchanged)
    TrailersPage(),    // 🎬 Trailers (unchanged)
    AccountPage(),     // 👤 Account
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 56,
        selectedIndex: index,
        backgroundColor: const Color(0xff0F0F0F),
        indicatorColor: const Color(0xffD4AF37).withOpacity(0.18),
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            label: "OTT",
          ),
          NavigationDestination(
            icon: Icon(Icons.theaters_outlined),
            label: "Trailers",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: "Account",
          ),
        ],
      ),
    );
  }
}
