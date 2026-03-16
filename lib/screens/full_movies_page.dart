import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_list_tile.dart';
import 'movie_detail_page.dart';

class FullMoviesPage extends StatefulWidget {
  const FullMoviesPage({super.key});

  @override
  State<FullMoviesPage> createState() => _FullMoviesPageState();
}

class _FullMoviesPageState extends State<FullMoviesPage> {
  final List _allFullMovies = [];

  Future<List> fetch() => MovieService.fetchFull();

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
          if (!_allFullMovies.contains(m)) {
            _allFullMovies.add(m);
          }

          return MovieListTile(
            id: m["unique_id"],
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractLanguage(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () {
              print("🟢 [EXPLORE FULL] Total=${_allFullMovies.length}");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(
                    data: m,
                    exploreList: _allFullMovies,
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
