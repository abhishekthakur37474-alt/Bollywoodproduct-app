import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movie_list_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/paginated_list.dart';
import '../services/dubbed_service.dart';
import '../utils/home_cache.dart';
import 'common.dart';

class DubbedMoviesPage extends StatefulWidget {
  const DubbedMoviesPage({super.key});

  @override
  State<DubbedMoviesPage> createState() => _DubbedMoviesPageState();
}

class _DubbedMoviesPageState extends State<DubbedMoviesPage> {
  Future<List> fetch() async {
    final list = await DubbedService.fetchDubbedMovies();
    HomeCache.dubbed = list;
    return list;
  }

  String _extractDubbedId(dynamic m) {
    final url = m["dubbing_lanaguage_url"]?.toString() ?? "";
    if (url.isEmpty) return "";
    final parts = url.split("-");
    if (parts.isNotEmpty) return parts.last;
    return "";
  }

  String? _resolveUniqueId(dynamic m) {
    final direct = m["film_unique_id"]?.toString().trim() ?? "";
    if (direct.isNotEmpty) return direct;
    return DataAdapter.extractUniqueIdFromFilmUrl(m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Latest Dubbed Movies",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PaginatedList(
        pageSize: 15,
        fetch: fetch,
        builder: (m) {
          final safeId = _extractDubbedId(m);
          if (safeId.isEmpty) return const SizedBox.shrink();

          return MovieListTile(
            id: safeId,
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractDubbedLanguage(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () {
              final uniqueId = _resolveUniqueId(m) ?? "";
              print("🟡 [DUBBED TAP] unique_id=$uniqueId");
              if (uniqueId.isEmpty) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonScreen(
                    uniqueId: uniqueId,
                    posterUrl: DataAdapter.extractPoster(m),
                    language: DataAdapter.extractDubbedLanguage(m),
                    onlyFullTrailers: false,
                    isDubbed: true,
                    exploreList: HomeCache.dubbed,
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