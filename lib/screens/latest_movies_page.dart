import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
import '../widgets/movie_list_tile.dart';
import 'common.dart';

class LatestMoviesPage extends StatefulWidget {
  const LatestMoviesPage({super.key});

  @override
  State<LatestMoviesPage> createState() => _LatestMoviesPageState();
}

class _LatestMoviesPageState extends State<LatestMoviesPage> {
  Future<List> fetch() => MovieService.fetchLatest();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Latest Movies in Theater"),
      ),
      body: PaginatedList(
        pageSize: 15,
        fetch: fetch,
        builder: (m) {
          return MovieListTile(
            id: m["film_unique_id"]?.toString() ?? "",
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractLanguage(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () async {
              final uniqueId = m["film_unique_id"]?.toString() ?? "";
              print("🟢 [LATEST TAP] unique_id=$uniqueId");
              if (uniqueId.isEmpty) return;

              final movie = await MovieService.fetchLatestByUniqueId(uniqueId);
              if (!context.mounted || movie == null) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonScreen(
                    uniqueId: uniqueId,
                    posterUrl: DataAdapter.extractPoster(m),
                    language: DataAdapter.extractLanguage(m),
                    onlyFullTrailers: false,
                    exploreList: HomeCache.latest,
                    isLatest: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}