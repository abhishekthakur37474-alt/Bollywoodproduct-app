import 'package:flutter/material.dart';
import '../utils/data_adapter.dart';
import '../screens/trailer_detail_page.dart';

class TrailerCard extends StatelessWidget {
  final Map data;

  const TrailerCard({
    super.key,
    required this.data,
  });

  /// 🔥 SMART CATEGORY DETECTION
  String detectCategory(String text) {
    final t = text.toLowerCase();

    if (t.contains("horror") || t.contains("ghost")) {
      return "Horror";
    }
    if (t.contains("comedy") || t.contains("funny")) {
      return "Comedy";
    }
    if (t.contains("thriller") ||
        t.contains("suspense") ||
        t.contains("crime")) {
      return "Thriller";
    }
    if (t.contains("action") || t.contains("fight")) {
      return "Action";
    }
    if (t.contains("romance") || t.contains("love")) {
      return "Romance";
    }
    if (t.contains("drama")) {
      return "Drama";
    }
    if (t.contains("teaser")) {
      return "Teaser";
    }
    if (t.contains("trailer")) {
      return "Trailer";
    }

    return "Trailer"; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final title = DataAdapter.extractTitle(data);
    final language =
    (data["language"] ??
        data["movie_language"] ??
        data["film_language"] ??
        "Hindi").toString();


    final combinedText =
        "$title ${data["description"] ?? ""}";

    final category = detectCategory(combinedText);

    final yt = DataAdapter.extractYoutubeId(data);
    final poster = yt == null
        ? null
        : "https://img.youtube.com/vi/$yt/0.jpg";

    print("🟡 [TRAILER CARD]");
    print("   ➜ Title: $title");
    print("   ➜ Language: $language");
    print("   ➜ Category: $category");
    print("   ➜ Poster: $poster");

    return GestureDetector(
      onTap: () {
        print("🟢 [OPEN TRAILER DETAIL] $title");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrailerDetailPage(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎬 TITLE FIRST
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            /// 🖼️ THUMBNAIL SECOND
            if (poster != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    poster,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white38,
                  size: 48,
                ),
              ),

            const SizedBox(height: 8),

            /// 🏷️ LANGUAGE + CATEGORY LAST
            Text(
              "$language • $category",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
