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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TrailerDetailPage(data: m)),
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