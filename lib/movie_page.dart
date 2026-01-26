import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'movie_detail_page.dart';
import 'movie_tile.dart';

class MoviePage extends StatefulWidget {
  const MoviePage({super.key});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  List<dynamic>? movies;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  Future<void> fetchMovies() async {
    setState(() => loading = true);
    final url = Uri.parse("https://hindi.bollywoodproduct.com/api-latest-movies.php");
    final res = await http.get(url);
    if (res.statusCode == 200) {
      movies = jsonDecode(res.body)["movies"];
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0E0E0E),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xffD4AF37)))
            : movies == null
            ? const Center(child: Text("Failed to load", style: TextStyle(color: Colors.white)))
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
                  Text("Bollywood Product",
                      style: TextStyle(color: Color(0xffD4AF37), fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Latest Releases",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
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
                // allocate space for poster + 2 lines of text
                childAspectRatio: 0.70,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final m = movies![i];
                  return MovieTile(
                    id: m["unique_id"],
                    title: m["name"],
                    year: m["year_release"]?.toString() ?? "-",
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => MovieDetailPage(id: m["unique_id"], title: m["name"])));
                    },
                  );
                },
                childCount: movies!.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
