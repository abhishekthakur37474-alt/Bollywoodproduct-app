import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_list_tile.dart';
import 'common.dart';

class FullMoviesPage extends StatefulWidget {
  const FullMoviesPage({super.key});

  @override
  State<FullMoviesPage> createState() => _FullMoviesPageState();
}

class _FullMoviesPageState extends State<FullMoviesPage> {
  Future<List> fetch() async {
    final data = await MovieService.fetchFull();
    print("=== [FULL MOVIES] Fetched: ${data.length} items");
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Latest Full Movies"),
      ),
      body: PaginatedList(
        pageSize: 15,
        fetch: fetch,
        builder: (m) {
          final uniqueId = DataAdapter.extractUniqueIdFromWatchUrl(m) ?? "";

          return MovieListTile(
            id: m["film_id"]?.toString() ?? uniqueId,
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractLanguage(m),
            categorySlug: DataAdapter.extractCategorySlug(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () {
              if (uniqueId.isEmpty) {
                print("🔴 [FULL MOVIE TAP] unique_id empty, film=${m["film_name"]}");
                return;
              }
              print("🟢 [FULL MOVIE TAP] navigating unique_id=$uniqueId");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonScreen(
                    uniqueId: uniqueId,
                    posterUrl: DataAdapter.extractPoster(m),
                    language: DataAdapter.extractLanguage(m),
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