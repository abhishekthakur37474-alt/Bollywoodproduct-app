import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_drawer.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';
import '../utils/home_cache.dart';
import '../services/movie_service.dart';
import '../services/ott_service.dart';
import 'common_detail_screen.dart';
import 'ott_detail_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  bool _isSearched = false;
  bool _showSuggestions = false;
  final Map<String, String?> _posterCache = {};
  final Map<String, Future<String?>> _posterFutures = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Search source: only api-films.php
  List<dynamic> _allMovies() {
    return [...HomeCache.films];
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions.clear();
        _showSuggestions = false;
      });
      return;
    }

    _getSuggestions(query);
  }

  void _getSuggestions(String query) {
    final seen = <String>{};
    final searchQuery = query.toLowerCase().trim();
    final suggestions = _allMovies().where((movie) {
      final title = DataAdapter.extractTitle(movie).toLowerCase().trim();
      final language = DataAdapter.extractLanguage(movie).toLowerCase().trim();
      if (!title.contains(searchQuery) && !language.contains(searchQuery)) return false;
      return seen.add(_dedupeKey(movie));
    }).take(5).toList();

    setState(() {
      _suggestions = suggestions;
      _showSuggestions = true;
    });
  }

  /// ✅ Normalized dedup key — prevents same movie appearing twice from different caches
  String _dedupeKey(dynamic m) {
    final id = m["unique_id"]?.toString() ??
                m["film_id"]?.toString() ??
                m["id"]?.toString();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final title = DataAdapter.extractTitle(m).toLowerCase().trim();
    final year = DataAdapter.extractYear(m).trim();
    return 'ty:$title||$year';
  }

  /// ✅ Find poster from other caches by unique_id — no API call needed
  String? _findPosterFromOtherCaches(String uniqueId) {
    final allCaches = [
      ...HomeCache.films,
    ];
    for (final m in allCaches) {
      final id = m["unique_id"]?.toString() ?? m["film_id"]?.toString();
      if (id == uniqueId) {
        final poster = DataAdapter.extractPoster(m);
        if (poster != null) return poster;
      }
    }
    return null;
  }

  Future<String?> _getMoviePoster(dynamic movie) async {
    final directPoster = DataAdapter.extractPoster(movie);
    if (directPoster != null) return directPoster;

    final uniqueId = movie["unique_id"]?.toString() ?? movie["film_id"]?.toString() ?? movie["id"]?.toString();
    if (uniqueId == null) return null;

    if (_posterCache.containsKey(uniqueId)) {
      return _posterCache[uniqueId];
    }

    // ✅ Try other caches first — instant, no API call
    final cachedPoster = _findPosterFromOtherCaches(uniqueId);
    if (cachedPoster != null) {
      _posterCache[uniqueId] = cachedPoster;
      return cachedPoster;
    }

    try {
      final res = await http.get(
        Uri.parse(
          "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=$uniqueId",
        ),
      );

      if (res.statusCode == 200 && res.body.startsWith("{")) {
        final raw = jsonDecode(res.body);
        String? posterUrl;

        if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
          posterUrl = raw["trailers"][0]["youtube_image_url"];
        }

        if (posterUrl == null || posterUrl.isEmpty) {
          posterUrl = raw["film_image"] ?? raw["poster_image_url"] ?? raw["poster"];
        }

        _posterCache[uniqueId] = posterUrl;
        return posterUrl;
      }
    } catch (e) {
      print("Error fetching poster for $uniqueId: $e");
    }

    _posterCache[uniqueId] = null;
    return null;
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _isSearched = true;
      _searchResults.clear();
    });

    try {
      final q = query.toLowerCase().trim();
      final seen = <String>{};

      // ✅ STEP 1: Search local cache (instant — includes HomeCache.films)
      var results = _allMovies().where((m) {
        final t = DataAdapter.extractTitle(m).toLowerCase().trim();
        final l = DataAdapter.extractLanguage(m).toLowerCase().trim();
        final y = DataAdapter.extractYear(m);
        if (!seen.add(_dedupeKey(m))) {
          print("🔴 [SEARCH DEDUP] SKIPPED: title=$t | lang=$l | year=$y");
          return false;
        }
        final match = t.contains(q) || l.contains(q);
        if (match) print("🟢 [SEARCH RESULT] title=$t | lang=$l | year=$y");
        return match;
      }).toList();

      print("🔵 [SEARCH TOTAL] ${results.length} results for '$q'");

      // ✅ STEP 2: API fallback if local empty (films not loaded yet)
      if (results.isEmpty && HomeCache.films.isEmpty) {
        print("🟡 [SEARCH] Local empty, fetching api-films.php");
        final res = await http.get(
          Uri.parse("https://www.bollywoodproduct.com/api-films.php"),
        );
        if (res.statusCode == 200 && res.body.trim().startsWith("{")) {
          final all = (jsonDecode(res.body)["movies"] ?? []) as List;
          HomeCache.films = all; // ✅ Cache for future searches
          print("🟢 [SEARCH] api-films.php loaded: ${all.length} items");

          results = all.where((m) {
            final t = DataAdapter.extractTitle(m).toLowerCase().trim();
            final l = DataAdapter.extractLanguage(m).toLowerCase().trim();
            return t.contains(q) || l.contains(q);
          }).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
          onChanged: _onSearchChanged,
          onSubmitted: (value) {
            setState(() {
              _showSuggestions = false;
            });
            _searchMovies(value);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _showSuggestions = false;
            });
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xffD4AF37)),
                )
              : !_isSearched
              ? _buildInitialScreen()
              : _searchResults.isEmpty
              ? _buildNoResultsScreen()
              : _buildResultsScreen(),
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xff0F0F0F),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.95),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Suggestions (${_suggestions.length})",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._suggestions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final movie = entry.value;
                            final title = DataAdapter.extractTitle(movie);
                            final language = DataAdapter.extractLanguage(movie);
                            final posterUrl = DataAdapter.extractPoster(movie);
                            final isLast = index == _suggestions.length - 1;

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showSuggestions = false;
                                      _searchController.text = title;
                                    });
                                    final isOtt = HomeCache.ott.contains(movie) ||
                                        HomeCache.ottLatest.contains(movie) ||
                                        HomeCache.ottUpcoming.contains(movie);
                                    if (isOtt) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => OttDetailPage(
                                            data: movie,
                                            exploreList: HomeCache.ott,
                                          ),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CommonDetailScreen(
                                            data: movie,
                                            exploreList: _suggestions,
                                            isLatest: true,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        // 🖼️ THUMBNAIL
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: SizedBox(
                                            width: 72,
                                            height: 42,
                                            child: posterUrl != null
                                                ? Image.network(
                                                    posterUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        _suggestionPlaceholder(),
                                                  )
                                                : _suggestionPlaceholder(),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // 📝 TITLE + LANGUAGE
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              () {
                                                final year = DataAdapter.extractYear(movie);
                                                final sub = [
                                                  if (language.isNotEmpty) language,
                                                  if (year.isNotEmpty) year,
                                                ].join(' • ');
                                                if (sub.isEmpty) return const SizedBox.shrink();
                                                return Padding(
                                                  padding: const EdgeInsets.only(top: 3),
                                                  child: Text(
                                                    sub,
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.5),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                );
                                              }(),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _suggestionPlaceholder() {
    return Container(
      color: const Color(0xff1a1a1a),
      child: Icon(Icons.movie, color: Colors.white.withOpacity(0.3), size: 20),
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
        final isOtt = HomeCache.ott.contains(movie) ||
            HomeCache.ottLatest.contains(movie) ||
            HomeCache.ottUpcoming.contains(movie);
        final isDubbed = HomeCache.dubbed.contains(movie);

        final safeId =
            movie["film_id"]?.toString() ??
            movie["unique_id"]?.toString() ??
            movie["ott_id"]?.toString() ??
            movie["id"]?.toString() ??
            "";

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
                    builder: (_) => CommonDetailScreen(
                      data: movie,
                      exploreList: _searchResults,
                      isLatest: true,
                    ),
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  DataAdapter.extractTitle(movie),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                /// POSTER (16:9)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: FutureBuilder<String?>(
                      future: _posterFutures.putIfAbsent(safeId, () => _getMoviePoster(movie)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff1a1a1a),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xffD4AF37),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }

                        final posterUrl = snapshot.data;
                        return Image.network(
                          posterUrl ??
                              "https://via.placeholder.com/640x360/1a1a1a/ffffff?text=No+Image",
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xffD4AF37),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
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
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                /// LANGUAGE + YEAR + CATEGORY
                Text(
                  [
                    DataAdapter.extractLanguage(movie),
                    DataAdapter.extractYear(movie),
                    isOtt ? 'OTT' : isDubbed ? 'Dubbed' : 'Movie',
                  ].where((s) => s.isNotEmpty).join(' • '),
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