import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MovieListTile extends StatefulWidget {
  final String id;
  final String title;
  final String language;
  final String? posterOverride;
  final VoidCallback onTap;

  const MovieListTile({
    super.key,
    required this.id,
    required this.title,
    required this.language,
    required this.onTap,
    this.posterOverride,
  });

  @override
  State<MovieListTile> createState() => _MovieListTileState();
}

class _MovieListTileState extends State<MovieListTile> {
  String? poster;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPoster();
  }

  Future<void> _loadPoster() async {
    print(" [MOVIE TILE] Loading poster for ID: ${widget.id}");
    print(" [MOVIE TILE] PosterOverride: ${widget.posterOverride}");

    // If posterOverride is available, use it directly
    if (widget.posterOverride != null && widget.posterOverride!.isNotEmpty) {
      print(" [MOVIE TILE] Using posterOverride: ${widget.posterOverride}");
      poster = widget.posterOverride;
      loading = false;
      setState(() {});
      return;
    }

    print(" [MOVIE TILE] No posterOverride, making API call...");

    // Only make API call if no poster is available
    try {
      final res = await http.get(
        Uri.parse(
          "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=${widget.id}",
        ),
      );

      if (res.statusCode == 200 && res.body.startsWith("{")) {
        final raw = jsonDecode(res.body);
        print(" [MOVIE TILE] API response keys: ${raw.keys.toList()}");
        if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
          poster = raw["trailers"][0]["youtube_image_url"];
          print(" [MOVIE TILE] Found poster from API: $poster");
        }
      }
    } catch (e) {
      print(" [MOVIE TILE] API call failed: $e");
    }

    loading = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// POSTER (BALANCED SIZE – LIKE OLD DESIGN)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: poster == null || poster!.isEmpty
                    ? Container(
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/logo.jpeg",
                                height: 40,
                                width: 40,
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
                                  fontSize: 10,
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
                                    height: 40,
                                    width: 40,
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
                                      fontSize: 10,
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

            const SizedBox(height: 6),

            /// 🎞 TITLE
            /// 🎞 TITLE (MORE PROMINENT)
            Text(
              widget.title,
              maxLines: 2, // 👈 allow 2 lines for clarity
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17, // ⬆ bigger
                fontWeight: FontWeight.w700,
                height: 1.25, // ⬆ better readability
              ),
            ),

            const SizedBox(height: 2),

            /// 🌐 LANGUAGE (CLEAR & DISTINCT)
            Text(
              widget.language,
              style: const TextStyle(
                color: Colors.white70, // ⬆ better contrast
                fontSize: 13.5, // ⬆ bigger
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
