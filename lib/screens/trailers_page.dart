import 'package:flutter/material.dart';
import 'all_trailers_page.dart';
import 'most_viewed_trailers_page.dart';
import 'latest_trailers_page.dart';

class TrailersPage extends StatelessWidget {
  const TrailersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xff0F0F0F),

        /// ✅ CLEAN APP BAR (NO EXTRA LINES)
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            "Trailers",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),

        body: Column(
          children: [
            /// 🔥 PREMIUM SEGMENTED TABS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xff161616),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent, // ❌ REMOVE LINE
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
                    Tab(text: "Latest Trailers"),
                    Tab(text: "Most Viewed"),
                  ],
                ),
              ),
            ),

            /// ✅ TAB CONTENT
            const Expanded(
              child: TabBarView(
                children: [LatestTrailersPage(), MostViewedTrailersPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
