import 'package:flutter/material.dart';

import '../services/trailer_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import 'trailer_detail_page.dart';

class LatestTrailersPage extends StatefulWidget {
  const LatestTrailersPage({super.key});

  @override
  State<LatestTrailersPage> createState() => _LatestTrailersPageState();
}

class _LatestTrailersPageState extends State<LatestTrailersPage>
    with AutomaticKeepAliveClientMixin {
  Future<List> fetch() => TrailerService.fetchLatestTrailers();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return PaginatedList(
      pageSize: 15,
      fetch: fetch,
      builder: (m) {
        final title = m["film_name"] ?? "Trailer";

        final languages =
            (m["languages"] as List?)
                ?.map((e) => e.toString())
                .toSet()
                .toList() ??
            ["Hindi"];

        final languageText = languages.first; // Only first language

        final trailerCategory = m["trailer_category"] ?? "Trailer";

        String? poster;

        /// 🔥 FIXED POSTER EXTRACTION

        if (m["trailers"] is List) {
          final trailers = m["trailers"] as List;
          for (final t in trailers) {
            final yt = DataAdapter.extractYoutubeId(t);
            if (yt != null) {
              poster = "https://img.youtube.com/vi/$yt/0.jpg";
              break;
            }
          }
        }

        if (poster == null) {
          final yt = DataAdapter.extractYoutubeId(m);
          if (yt != null) {
            poster = "https://img.youtube.com/vi/$yt/0.jpg";
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TrailerDetailPage(data: m)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ TITLE FIRST
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                /// ✅ POSTER SECOND (LIKE BEFORE)
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
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),

                const SizedBox(height: 8),

                /// ✅ LANGUAGE + CATEGORY LAST (LIKE BEFORE)
                Text(
                  "$languageText • $trailerCategory",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
