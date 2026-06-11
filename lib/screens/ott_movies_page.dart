import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'latest_ott.dart';
import 'upcoming_ott.dart';

class OttMoviesPage extends StatelessWidget {
  const OttMoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xff0F0F0F),
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              "OTT Movies",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          body: Column(
            children: [
              /// 🔥 PILL TABS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xff161616),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xffE6C15A), Color(0xffC9A43A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: "Latest OTT"),
                      Tab(text: "Upcoming OTT"),
                    ],
                  ),
                ),
              ),

              const Expanded(
                child: TabBarView(
                  children: [
                    LatestOttPage(),
                    UpcomingOttPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}