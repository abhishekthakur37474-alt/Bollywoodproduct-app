import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movie_list_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/paginated_list.dart';
import '../services/dubbed_service.dart';
import '../utils/home_cache.dart';
import 'common_detail_screen.dart';

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

  Map _normalizeData(dynamic m) {
    final directors = (m["directors"] as List?)
            ?.map((d) => d["name"]?.toString() ?? "")
            .where((n) => n.isNotEmpty)
            .join(", ") ??
            
        "";
        

    final genres = (m["genres"] as List?)
            ?.map((g) => g["name"]?.toString() ?? "")
            .where((n) => n.isNotEmpty)
            .join(", ") ??
        "";

    final cast = (m["lead_cast"] as List?)
            ?.map((c) => c["name"]?.toString() ?? "")
            .where((n) => n.isNotEmpty)
            .join(", ") ??
        "";

    print("DEBUG cast=$cast isDubbed=true");
    return {
      ...m,
      "film_name": m["dubbed_film_name"] ?? m["original_film_name"] ?? "",
      "film_lang": m["dubbed_film_language"] ?? "",
      "film_image_url": m["youtube_thumbnail"] ?? "",
      "film_watch_url": m["youtube_watch_url"] ?? "",
      "youtube_watch_url": m["youtube_watch_url"] ?? "",
      "directors": directors,
      "producers": "",
      "genre_list": genres,
      "release_date_formatted": m["full_date"] ?? "",
      "lead_cast_list": cast,
    };
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonDetailScreen(
                    data: _normalizeData(m),
                    exploreList: HomeCache.dubbed,
                    isDubbed: true,
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