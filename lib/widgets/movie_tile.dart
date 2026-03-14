import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MovieTile extends StatefulWidget {
  final String id;
  final String title;
  final String year;
  final VoidCallback onTap;

  const MovieTile({
    super.key,
    required this.id,
    required this.title,
    required this.year,
    required this.onTap,
  });

  @override
  State<MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<MovieTile> {
  String? poster;

  @override
  void initState() {
    super.initState();
    fetchPoster();
  }

  Future<void> fetchPoster() async {
    final url = Uri.parse(
        "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=${widget.id}");

    final res = await http.get(url);

    if (!mounted) return; // prevents setState after dispose

    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body);
      if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
        poster = raw["trailers"][0]["youtube_image_url"];
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // POSTER
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9, // correct trailer ratio
              child: poster == null
                  ? Container(color: Colors.white10)
                  : Image.network(
                poster!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // TITLE + YEAR
          Text(
            "${widget.title} (${widget.year})",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
