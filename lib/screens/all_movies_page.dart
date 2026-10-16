import '../services/movie_service.dart';
import 'package:flutter/material.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
import '../widgets/movie_list_tile.dart';
import 'common.dart';

class AllMoviesPage extends StatefulWidget {
  const AllMoviesPage({super.key});

  @override
  State<AllMoviesPage> createState() => _AllMoviesPageState();
}

class _AllMoviesPageState extends State<AllMoviesPage> {
  Future<List> fetch() => MovieService.fetchLatest();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Latest Movies"),
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
            onTap: () {
              final uniqueId = m["film_unique_id"]?.toString() ?? "";
              print("🟢 [ALL MOVIES TAP] unique_id=$uniqueId");
              if (uniqueId.isEmpty) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonScreen(
                    uniqueId: uniqueId,
                    posterUrl: DataAdapter.extractPoster(m),
                    language: DataAdapter.extractLanguage(m),
                    onlyFullTrailers: false,
                    exploreList: HomeCache.latest,
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