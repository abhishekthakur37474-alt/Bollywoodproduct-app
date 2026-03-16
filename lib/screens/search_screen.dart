import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_drawer.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
import '../services/movie_service.dart';
import '../services/ott_service.dart';
import 'movie_detail_page.dart';
import 'ott_detail_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _isSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _isSearched = true;
      _searchResults.clear();
    });

    try {
      // Search in all cached data
      final allMovies = [
        ...HomeCache.latest,
        ...HomeCache.upcoming,
        ...HomeCache.full,
        ...HomeCache.ott,
        ...HomeCache.dubbed,
      ];

      final results = allMovies.where((movie) {
        final title = DataAdapter.extractTitle(movie).toLowerCase().trim();
        final language = DataAdapter.extractLanguage(
          movie,
        ).toLowerCase().trim();
        final searchQuery = query.toLowerCase().trim();

        return title.contains(searchQuery) || language.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search movies...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _searchMovies(_searchController.text),
            ),
          ),
          onSubmitted: (value) => _searchMovies(value),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffD4AF37)),
            )
          : !_isSearched
          ? _buildInitialScreen()
          : _searchResults.isEmpty
          ? _buildNoResultsScreen()
          : _buildResultsScreen(),
    );
  }

  Widget _buildInitialScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Search for movies',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter_outlined,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'No movies found',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for "${_searchController.text}"',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final movie = _searchResults[index];
        final isOtt = HomeCache.ott.contains(movie);
        final isDubbed = HomeCache.dubbed.contains(movie);

        final safeId = isOtt
            ? movie["film_id"]?.toString() ??
                  movie["unique_id"]?.toString() ??
                  movie["id"]?.toString() ??
                  ""
            : movie["unique_id"]?.toString() ?? "";

        if (safeId.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: GestureDetector(
            onTap: () {
              if (isOtt) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OttDetailPage(data: movie, exploreList: HomeCache.ott),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailPage(
                      data: movie,
                      exploreList: _searchResults,
                    ),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE FIRST
                Text(
                  DataAdapter.extractTitle(movie),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                /// POSTER SECOND (16:9 ASPECT RATIO LIKE TRAILERS)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      DataAdapter.extractPoster(movie) ??
                          "https://via.placeholder.com/640x360/1a1a1a/ffffff?text=No+Image",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xff1a1a1a),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie,
                                color: Colors.white.withOpacity(0.4),
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Poster not available",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// LANGUAGE + CATEGORY LAST
                Text(
                  "${DataAdapter.extractLanguage(movie)} • ${isOtt
                      ? 'OTT'
                      : isDubbed
                      ? 'Dubbed'
                      : 'Movie'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
