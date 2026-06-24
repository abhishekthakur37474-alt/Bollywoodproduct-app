import 'package:flutter/material.dart';
import '../services/movie_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_list_tile.dart';
import 'common_detail_screen.dart';
import '../utils/home_cache.dart';

class UpcomingMoviesPage extends StatefulWidget {
  const UpcomingMoviesPage({super.key});

  @override
  State<UpcomingMoviesPage> createState() => _UpcomingMoviesPageState();
}

class _UpcomingMoviesPageState extends State<UpcomingMoviesPage> {
  final List _allUpcoming = [];

  Future<List> fetch() => MovieService.fetchUpcoming();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Upcoming Movies"),
      ),
      body: PaginatedList(
        pageSize: 15,
        fetch: fetch,
        builder: (m) {
          if (!_allUpcoming.contains(m)) {
            _allUpcoming.add(m);
          }

          return MovieListTile(
            id: m["unique_id"],
            title: DataAdapter.extractTitle(m),
            language: DataAdapter.extractLanguage(m),
            posterOverride: DataAdapter.extractPoster(m),
            onTap: () {
              print("🟢 [EXPLORE UPCOMING] Total=${_allUpcoming.length}");

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CommonDetailScreen(
                    data: m,
                    exploreList: _allUpcoming,
                    isUpcoming: true,
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