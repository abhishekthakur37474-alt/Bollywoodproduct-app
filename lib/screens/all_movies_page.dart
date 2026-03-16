import '../services/movie_service.dart';
import 'package:flutter/material.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_list_tile.dart';
import 'movie_detail_page.dart';

class AllMoviesPage extends StatefulWidget {
  const AllMoviesPage({super.key});

  @override
  State<AllMoviesPage> createState() => _AllMoviesPageState();
}

class _AllMoviesPageState extends State<AllMoviesPage> {
  final List _allMovies = []; // 🔥 KEEP THIS (IMPORTANT)

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
          // 🔥 COLLECT FOR EXPLORE MORE
          if (!_allMovies.contains(m)) {
            _allMovies.add(m);
          }

          return MovieListTile(
            id: m["unique_id"],
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractLanguage(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () {
              print("🟢 [EXPLORE] Current movie ID: ${m["unique_id"]}");
              print("🟢 [EXPLORE MORE] Showing ${_allMovies.length} movies");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(
                    data: m,
                    exploreList: _allMovies, // ✅ FIXED (NO MORE 1 MOVIE)
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
