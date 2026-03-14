import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'movie_detail_page.dart';

class MovieDetailPage extends StatefulWidget {
  final String id;
  final String title;

  const MovieDetailPage({super.key, required this.id, required this.title});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool loading = true;

  String name = "-";
  String year = "-";
  String genre = "-";
  String language = "-";
  String director = "Unknown";
  List<String> cast = [];
  String? poster;
  String? trailerUrl;

  List<Map<String, dynamic>> moreMovies = [];
  bool loadingMore = true;

  @override
  void initState() {
    super.initState();
    fetchDetails();
    fetchMoreMovies();
  }

  Future<void> fetchMoreMovies() async {
    final url = Uri.parse("https://hindi.bollywoodproduct.com/api-latest-movies.php");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body)["movies"] as List;
      final sliced = list.take(10).toList();

      for (var m in sliced) {
        final detail = await fetchPoster(m["unique_id"]);
        moreMovies.add({
          "id": m["unique_id"],
          "title": m["name"],
          "poster": detail,
        });
      }
    }

    if (mounted) setState(() => loadingMore = false);
  }

  Future<String?> fetchPoster(String id) async {
    final u = Uri.parse("https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=$id");
    final r = await http.get(u);
    if (r.statusCode != 200) return null;
    final raw = jsonDecode(r.body);
    if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
      return raw["trailers"][0]["youtube_image_url"];
    }
    return null;
  }

  Future<void> fetchDetails() async {
    final url = Uri.parse("https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=${widget.id}");
    final res = await http.get(url);

    if (res.statusCode != 200) {
      setState(() => loading = false);
      return;
    }

    final raw = jsonDecode(res.body);
    name = raw["film_name"] ?? widget.title;
    year = raw["year_release"]?.toString() ?? "-";

    if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
      final t = raw["trailers"][0];
      poster = t["youtube_image_url"];
      if (t["teaser"] != null && t["teaser"] != "") {
        trailerUrl = "https://youtube.com/watch?v=${t["teaser"]}";
      }
    }

    final schemaRaw = raw["schema"];
    if (schemaRaw is String && schemaRaw.trim().isNotEmpty) {
      final pieces = schemaRaw.split("</script>");
      for (var p in pieces) {
        var block = p.replaceAll(RegExp(r'<script[^>]*>'), '').trim();
        if (!block.startsWith("{")) continue;
        try {
          final data = jsonDecode(block);
          if (data["@type"] == "Movie") {
            if (data["genre"] is List) genre = (data["genre"] as List).join(", ");
            if (data["inLanguage"] is String) language = data["inLanguage"];
            if (data["director"] is Map && data["director"]["name"] != null) director = data["director"]["name"];
            if (data["actor"] is List) {
              cast = data["actor"].map<String>((a) => a["name"].toString()).toList();
            }
            break;
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : buildContent(),
    );
  }

  Widget buildContent() {
    final truncatedCast =
    cast.isEmpty ? "-" : "${cast.take(2).join(", ")}${cast.length > 2 ? " +${cast.length - 2}" : ""}";

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 310,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            title: Text("$name ", style: const TextStyle(fontSize: 18)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                poster != null ? Image.network(poster!, fit: BoxFit.cover) : Container(color: Colors.black),
                Container(color: Colors.black.withOpacity(0.45)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow("Genre", genre),
                infoRow("Language", language),
                infoRow("Director", director),
                GestureDetector(onTap: cast.isEmpty ? null : showCastSheet, child: infoRow("Cast", truncatedCast)),
                const SizedBox(height: 26),
                const Text("Trailers",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xffD4AF37))),
                const SizedBox(height: 12),
                trailerButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        // Explore Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: const Text("Explore More Movies",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 190,
            child: loadingMore
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: moreMovies.length,
              itemBuilder: (context, i) {
                final m = moreMovies[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => MovieDetailPage(id: m["id"], title: m["title"])));
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: m["poster"] == null
                                ? Container(color: Colors.white10)
                                : Image.network(m["poster"], fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(m["title"],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget trailerButton() {
    if (trailerUrl == null) {
      return Text("No Trailers", style: TextStyle(color: Colors.grey.shade400));
    }

    return ElevatedButton(
      onPressed: () async {
        final uri = Uri.parse(trailerUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text("Watch Trailer", style: TextStyle(fontSize: 16)),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey.shade300, fontSize: 14))),
        ],
      ),
    );
  }

  void showCastSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Full Cast", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 16),
            ...cast.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(c, style: const TextStyle(fontSize: 15, color: Colors.white)),
            )),
          ]),
        );
      },
    );
  }
}
