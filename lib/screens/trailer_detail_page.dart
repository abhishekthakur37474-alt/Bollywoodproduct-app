import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/data_adapter.dart';

class TrailerDetailPage extends StatelessWidget {
  final Map data;

  const TrailerDetailPage({super.key, required this.data});

  /// 🔥 Extract trailers (supports grouped structure)
  List<Map> extractTrailers() {
    if (data["trailers"] is List) {
      return List<Map>.from(data["trailers"]);
    }
    return [data];
  }

  /// 🔥 Extract all trailers with valid URLs
  List<Map> extractAllTrailers() {
    final trailers = extractTrailers();
    final validTrailers = <Map>[];

    for (final trailer in trailers) {
      final ytId = DataAdapter.extractYoutubeId(trailer);
      final teaserUrl = trailer["teaser"]?.toString();

      // Add if we have either valid YouTube ID or teaser URL
      if (ytId != null || (teaserUrl != null && teaserUrl.isNotEmpty)) {
        validTrailers.add(trailer);
      }
    }

    return validTrailers;
  }

  /// 🔥 Get poster from first valid trailer
  String? getPoster() {
    final trailers = extractTrailers();

    for (final t in trailers) {
      final yt = DataAdapter.extractYoutubeId(t);
      if (yt != null) {
        return "https://img.youtube.com/vi/$yt/0.jpg";
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final title = data["film_name"] ?? "Trailer";
    final allTrailers = extractAllTrailers();
    final poster = getPoster();

    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(backgroundColor: Colors.black, title: Text(title)),
      body: ListView(
        // ✅ FIXED OVERFLOW (SCROLLABLE)
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          /// 🎬 POSTER
          if (poster != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(poster, fit: BoxFit.cover),
              ),
            ),

          const SizedBox(height: 24),

          /// 🎥 WATCH BUTTONS (MULTI LANGUAGE)
          ...allTrailers.map((t) {
            final ytId = DataAdapter.extractYoutubeId(t);
            final language = (t["language"] ?? "Trailer").toString();
            final trailerCategory = (t["trailer_category"] ?? "Trailer")
                .toString();
            final teaserUrl = t["teaser"]?.toString();

            // Capitalize first letter for better display
            final displayLanguage = language.isEmpty
                ? "Trailer"
                : language[0].toUpperCase() +
                      language.substring(1).toLowerCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Use teaser URL if available, otherwise YouTube
                    final url = teaserUrl != null && teaserUrl.isNotEmpty
                        ? Uri.parse(teaserUrl.trim())
                        : ytId != null
                        ? Uri.parse("https://www.youtube.com/watch?v=$ytId")
                        : null;

                    if (url != null) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Watch $trailerCategory in $displayLanguage",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 26),

          /// 📢 DISCLAIMER CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Disclaimer",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Trailers and videos are embedded from official public sources. "
                  "Bollywood Product does not host or upload any video content.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showDisclaimerModal(context),
                  child: const Text(
                    "[ Read More ]",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 🔥 READ MORE MODAL
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
                "Trailers and videos shown in this app are embedded from official "
                "publicly available sources such as YouTube.\n\n"
                "Bollywood Product does not host, upload, or store any video files "
                "on its servers.\n\n"
                "All copyrights belong to their respective owners. "
                "Users are encouraged to watch content directly on the official platforms.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
