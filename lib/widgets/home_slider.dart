import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/home_cache.dart';
import '../utils/data_adapter.dart';
import '../screens/movie_detail_page.dart';

class HomeSlider extends StatefulWidget {
  const HomeSlider({super.key});

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  final PageController _controller = PageController();
  Timer? _timer;
  int index = 0;

  late final List<Map> slides;

  @override
  void initState() {
    super.initState();

    slides = [
      if (HomeCache.latest.isNotEmpty) HomeCache.latest.first,
      if (HomeCache.upcoming.isNotEmpty) HomeCache.upcoming.first,
      if (HomeCache.full.isNotEmpty) HomeCache.full.first,
    ];

    print("🟢 [HOME SLIDER] Items=${slides.length}");

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_controller.hasClients && slides.isNotEmpty) {
        index = (index + 1) % slides.length;
        _controller.animateToPage(
          index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// 🎯 ONLY YOUTUBE THUMBNAIL (FINAL FIX)
  String? resolveYoutubePoster(Map m) {
    final yt = DataAdapter.extractYoutubeId(m);

    if (yt == null || yt.isEmpty) {
      print("🔴 [SLIDER YT FAIL] No YouTube ID");
      return null;
    }

    final poster = "https://img.youtube.com/vi/$yt/0.jpg";
    print("🟢 [SLIDER YT POSTER] $poster");
    return poster;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (slides.isEmpty) {
      return const SizedBox(height: 220);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            itemBuilder: (_, i) {
              final m = slides[i];
              final title = DataAdapter.extractTitle(m);
              final poster = resolveYoutubePoster(m);

              print("🟡 [HOME SLIDER ITEM] $title → $poster");

              if (poster == null) {
                return Container(color: Colors.black);
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MovieDetailPage(data: m, exploreList: slides),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      poster,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        print("🔴 [SLIDER IMAGE ERROR] $title");
                        return Container(color: Colors.black);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
