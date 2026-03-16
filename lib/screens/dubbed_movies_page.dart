import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
import '../services/dubbed_service.dart';
import 'movie_detail_page.dart';

class DubbedMoviesPage extends StatefulWidget {
  const DubbedMoviesPage({super.key});

  @override
  State<DubbedMoviesPage> createState() => _DubbedMoviesPageState();
}

class _DubbedMoviesPageState extends State<DubbedMoviesPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDubbedMovies();
  }

  Future<void> _loadDubbedMovies() async {
    await DubbedService.fetchDubbed();
    setState(() {
      isLoading = false;
    });
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffD4AF37)),
            )
          : HomeCache.dubbed.isEmpty
              ? const Center(
                  child: Text(
                    "No dubbed movies available",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: HomeCache.dubbed.length,
                  itemBuilder: (context, index) {
                    final movie = HomeCache.dubbed[index];
                    final safeId = movie["unique_id"]?.toString() ?? "";

                    if (safeId.isEmpty) return const SizedBox.shrink();

                    return MovieTile(
                      id: safeId,
                      title: DataAdapter.extractTitle(movie),
                      year: DataAdapter.extractLanguage(movie),
                      posterOverride: DataAdapter.extractPoster(movie),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MovieDetailPage(
                              data: movie,
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
