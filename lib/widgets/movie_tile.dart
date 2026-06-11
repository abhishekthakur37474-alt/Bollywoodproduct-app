import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MovieTile extends StatefulWidget {
  final String id;
  final String title;
  final String year;
  final VoidCallback onTap;
  final String? posterOverride;

  const MovieTile({
    super.key,
    required this.id,
    required this.title,
    required this.year,
    required this.onTap,
    this.posterOverride,
  });

  @override
  State<MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<MovieTile> {
  String? poster;
  bool loadingPoster = true;

  @override
  void initState() {
    super.initState();
    fetchPoster();
  }

  Future<void> fetchPoster() async {
    if (widget.posterOverride != null) {
      poster = widget.posterOverride;
      loadingPoster = false;
      setState(() {});
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=${widget.id}",
        ),
      );

      if (res.statusCode == 200 && res.body.startsWith("{")) {
        final raw = jsonDecode(res.body);
        if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
          poster = raw["trailers"][0]["youtube_image_url"];
        }
      }
    } catch (_) {}

    loadingPoster = false;
    if (mounted) setState(() {});
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 182, // 🔥 NETFLIX WIDTH
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 🔥 NO EXTRA HEIGHT
          children: [
            /// 🎬 POSTER (16:9 ASPECT RATIO)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 102, // 🔥 16:9 ratio (135 * 9 / 16 = 76)
                width: double.infinity,
                child: poster == null || poster!.isEmpty
                    ? Container(
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/logo.jpeg",
                                height: 32,
                                width: 32,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.movie,
                                    color: Colors.white30,
                                    size: 28,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Bollywood Product",
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.network(
                        poster!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade900,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    "assets/images/logo.jpeg",
                                    height: 32,
                                    width: 32,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.movie,
                                        color: Colors.white30,
                                        size: 28,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Bollywood Product",
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 3), // 🔥 MIN GAP
            /// 🎞 TITLE
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.1, // 🔥 COMPACT LINE HEIGHT
              ),
            ),

            /// 🌐 LANGUAGE
            Text(
              widget.year,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}