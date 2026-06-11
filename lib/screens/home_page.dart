import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
// import '../widgets/notification_sheet.dart';
import 'ott_movies_page.dart';
import 'movie_detail_page.dart';
import 'all_movies_page.dart';
import 'upcoming_movies_page.dart';
import 'full_movies_page.dart';
import 'ott_detail_page.dart';
import 'search_screen.dart';
import 'dubbed_movies_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ✅ DATA ALREADY LOADED IN SPLASH
  @override
  void initState() {
    super.initState();
    print("🟢 [HOME PAGE] Using cached data from splash");
  }

  void _showDisclaimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Disclaimer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "OTT platforms shown in this app are for informational purposes only.\n\n"
                "Bollywood Product does not host, stream, upload, or distribute any OTT content.\n\n"
                "All trademarks, platform names, and content belong to their respective owners.\n\n"
                "Users must watch content directly on the official OTT platforms using their subscriptions.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullMoviesDisclaimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Disclaimer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                "Full movies shown in this app are official YouTube videos embedded from publicly available sources.\n\n"
                "Bollywood Product does not host, upload, or distribute any movie content.\n\n"
                "All rights belong to the respective copyright owners and YouTube channels.\n\n"
                "Users watch videos directly through YouTube.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ FIXED METHOD (your resolveOttId broken tha)
  String resolveOttId(dynamic m) {
    final id = m["film_id"] ?? m["unique_id"] ?? m["id"];

    return id?.toString() ?? "";
  }

  // ✅ NEW: Extract ID from dubbed movie URL
  String _extractDubbedId(dynamic m) {
    final url = m["dubbing_lanaguage_url"]?.toString() ?? "";
    if (url.isEmpty) return "";

    // Extract ID from URL like "https://www.bollywoodproduct.com/media-mission-118-hindi-dubbed-film-137"
    final parts = url.split("-");
    if (parts.isNotEmpty) {
      return parts.last; // Get the last part which should be the ID
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      extendBody: true,
      drawer: const AppDrawer(),

      appBar: AppBar(
        backgroundColor: Colors.black,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            Image.asset("assets/images/logo.jpeg", height: 36),
            const SizedBox(width: 8),
            const Text(
              "Bollywood Product",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.notifications_none),
          //   onPressed: () {
          //     if (FirebaseAuth.instance.currentUser == null) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text("Please login first")),
          //       );
          //       return;
          //     }

          //     showModalBottomSheet(
          //       context: context,
          //       backgroundColor: Colors.transparent,
          //       isScrollControlled: true,
          //       builder: (_) => NotificationSheet(),
          //     );
          //   },
          // ),
          const SizedBox(width: 8),
        ],
      ),

      /// 🔥 NETFLIX-STYLE LIST
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            section(
              context,
              key: "full",
              title: "Full Movies",
              list: HomeCache.full,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FullMoviesPage()),
              ),
            ),
            // REPLACE dubbed section with:
            ValueListenableBuilder<List>(
              valueListenable: HomeCache.dubbedNotifier,
              builder: (context, dubbedList, child) {
                return section(
                  context,
                  key: "dubbed",
                  title: "Latest Dubbed Movies",
                  list: dubbedList.isNotEmpty ? dubbedList : HomeCache.dubbed,
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DubbedMoviesPage()),
                  ),
                );
              },
            ),
            section(
              context,
              key: "upcoming",
              title: "Upcoming Movies",
              list: HomeCache.upcoming,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpcomingMoviesPage()),
              ),
            ),
            section(
              context,
              key: "latest",
              title: "Latest Movies in Theater",
              list: HomeCache.latest,
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllMoviesPage()),
              ),
            ),

            /// 🔥 OTT SECTION with ValueListenableBuilder for auto-refresh
            ValueListenableBuilder<List>(
              valueListenable: HomeCache.ottNotifier,
              builder: (context, ottList, child) {
                return section(
                  context,
                  key: "ott",
                  title: "Latest OTT Movies",
                  list: ottList.isNotEmpty ? ottList : HomeCache.ott,
                  onSeeAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OttMoviesPage()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget section(
    BuildContext context, {
    required String key,
    required String title,
    required List list,
    required VoidCallback onSeeAll,
  }) {
    final items = list.take(10).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: Color(0xffD4AF37),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          /// ✅ SMALL CLEAN FULL MOVIES DISCLAIMER
          if (key == "full")
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.white54,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Official YouTube videos are embedded. "
                          "Bollywood Product does not host or upload these movies.",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _showFullMoviesDisclaimer(context),
                          child: const Text(
                            "Read more",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          /// ✅ SMALL CLEAN OTT DISCLAIMER WITH ICON
          if (key == "ott")
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "OTT platforms are shown for informational purposes only. "
                              "This app does not host or stream any OTT content.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => _showDisclaimerModal(context),
                              child: const Text(
                                "Read more",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Show loading indicator or empty state (skip loading for OTT)
          if (items.isEmpty && !HomeCache.loaded && key != "ott")
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 12),
              child: Row(
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xffD4AF37),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Loading $title...",
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (items.isEmpty)
            const SizedBox.shrink()
          else
            SizedBox(
              height: 140,
              child: ListView.builder(
                key: PageStorageKey(key),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final m = items[i];
                  final isOtt = key == "ott";
                  final isDubbed = key == "dubbed";

                  final safeId = isOtt
                      ? resolveOttId(m)
                      : isDubbed
                      ? _extractDubbedId(m)
                      : (m["film_id"]?.toString() ??
                            m["unique_id"]?.toString() ??
                            "");

                  if (safeId.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: MovieTile(
                      id: safeId,
                      title: DataAdapter.extractTitle(m),
                      year: isDubbed
                          ? DataAdapter.extractDubbedLanguage(m)
                          : (isOtt
                                ? DataAdapter.extractLanguage(m)
                                : (key == "upcoming" || key == "latest")
                                ? DataAdapter.extractLanguage(m)
                                : "${DataAdapter.extractCategorySlug(m)} in ${DataAdapter.extractLanguage(m)}"),
                      onTap: () {
                        if (isOtt) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OttDetailPage(
                                data: m,
                                exploreList: HomeCache.ott,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailPage(data: m, exploreList: items),
                            ),
                          );
                        }
                      },
                      posterOverride: DataAdapter.extractPoster(m),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}