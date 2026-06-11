import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'movie_detail_page.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';

class MoviePage extends StatefulWidget {
  const MoviePage({super.key});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  List movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    final url = Uri.parse("https://bollywoodproduct.com/api-latest-movies.php");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
        movies = jsonDecode(res.body)["movies"] ?? [];
      }
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0E0E0E),
      body: SafeArea(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xffD4AF37)),
              )
            : movies.isEmpty
            ? const Center(
                child: Text(
                  "Failed to load",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : buildGrid(),
      ),
    );
  }

  Widget buildGrid() {
    return RefreshIndicator(
      color: const Color(0xffD4AF37),
      onRefresh: fetchMovies,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Bollywood Product",
                    style: TextStyle(
                      color: Color(0xffD4AF37),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Latest Releases",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                final m = movies[i];

                return MovieTile(
                  id: m["unique_id"],
                  title: DataAdapter.extractTitle(m),
                  year: DataAdapter.extractYear(m),
                  posterOverride: DataAdapter.extractPoster(m), // ✅ SAME AS OTT
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(
                          data: m, // ✅ PASS FULL DATA
                          exploreList: movies.take(20).toList(), // ✅ FAST
                        ),
                      ),
                    );
                  },
                );
              }, childCount: movies.length),
            ),
          ),
        ],
      ),
    );
  }
}
