import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import 'common.dart';

class MostViewedTrailersPage extends StatelessWidget {
  const MostViewedTrailersPage({super.key});

  static const apiUrl =
      "https://www.bollywoodproduct.com/api-most-viewed-trailers.php";

  Future<List> fetch() async {
    print("🟡 [MOST VIEWED] Fetching trailers");

    final res = await http.get(Uri.parse(apiUrl));

    if (res.statusCode != 200) return [];

    final raw = jsonDecode(res.body);
    final List rawList = raw["trailers"] ?? [];

    print("🟢 [MOST VIEWED] Received: ${rawList.length}");
    return rawList;
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedList(
      pageSize: 15,
      fetch: fetch,
      builder: (m) {
        final title = m["film_name"] ?? m["trailer_name"] ?? "Trailer";
        final language = (m["language"] ?? "Hindi").toString();
        final trailerCategory = m["trailer_category"] ?? "Trailer";
        final releaseDate = m["release_date"]?.toString() ?? "";

        final yt = DataAdapter.extractYoutubeId(m);
        final String? poster = yt != null
            ? "https://img.youtube.com/vi/$yt/0.jpg"
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: GestureDetector(
            onTap: () {
              // ✅ SAME method as common page (home_page.dart / latest_trailers_page.dart)
              final uniqueId = m["film_unique_id"]?.toString().trim() ?? "";
              if (uniqueId.isEmpty) {
                print("🔴 [MOST VIEWED TAP] film_unique_id empty, film=$title");
                return;
              }
              print("🟢 [MOST VIEWED TAP] → unique_id=$uniqueId");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonScreen(
                    uniqueId: uniqueId,
                    posterUrl: poster,
                    language: language,
                    onlyFullTrailers: false,
                    exploreList: const [],
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                if (poster != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(poster, fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_outline,
                        color: Colors.white38, size: 48),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "$language • $trailerCategory",
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withOpacity(0.6)),
                    ),
                    if (releaseDate.isNotEmpty) ...[
                      Text(
                        "  •  $releaseDate",
                        style: TextStyle(
                            fontSize: 12, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}