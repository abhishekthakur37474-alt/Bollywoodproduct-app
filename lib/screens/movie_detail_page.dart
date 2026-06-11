import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';
import '../services/report_service.dart';

class MovieDetailPage extends StatefulWidget {
  final Map data;
  final List exploreList;

  const MovieDetailPage({
    super.key,
    required this.data,
    required this.exploreList,
  });

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  bool loading = true;

  late String name;
  late String year;

  String genre = "";
  String language = "";
  String director = "";
  List<String> cast = [];

  // 🔥 NEW CBFC FIELDS
  String cbfcRating = "";
  String cbfcNumber = "";
  String cbfcDate = "";
  String runningTime = "";
  bool _showMoreInfo = false;

// New Issue date for latest movies 
String releaseDate = "";
String releaseDateFormatted = "";

  String? poster;
  String? trailerUrl;

  @override
  void initState() {
    super.initState();
    name = DataAdapter.extractTitle(widget.data);
    year = DataAdapter.extractYear(widget.data);
    poster = DataAdapter.extractPoster(widget.data);
    print("======== MOVIE DETAIL DEBUG ========");
    print("Movie Name: $name");
    print("Unique ID: ${widget.data["unique_id"]}");
    print("CBFC from LIST API:");
    print("cbfc_rating: ${widget.data["cbfc_rating"]}");
    print("cbfc_certificate_no: ${widget.data["cbfc_certificate_no"]}");
    print("cbfc_certificate_date: ${widget.data["cbfc_certificate_date"]}");
    print("cbfc_certificate_month: ${widget.data["cbfc_certificate_month"]}");
    print("cbfc_certificate_year: ${widget.data["cbfc_certificate_year"]}");
    print("=====================================");

    /// ✅ CBFC FROM LIST API (IMPORTANT)
    cbfcRating = widget.data["cbfc_rating"]?.toString() ?? "";
    cbfcNumber = widget.data["cbfc_certificate_no"]?.toString() ?? "";

    final d = widget.data["cbfc_certificate_date"]?.toString() ?? "";
    final m = widget.data["cbfc_certificate_month"]?.toString() ?? "";
    final y = widget.data["cbfc_certificate_year"]?.toString() ?? "";

    if (d.isNotEmpty && m.isNotEmpty && y.isNotEmpty) {
      cbfcDate = "$d/$m/$y";
    }

    // ✅ RUNNING TIME from cbfc fields only
    final rtMin = int.tryParse(widget.data["cbfc_running_time_minutes"]?.toString() ?? "") ?? 0;
    final rtSec = int.tryParse(widget.data["cbfc_running_time_seconds"]?.toString() ?? "") ?? 0;
    if (rtMin > 0 || rtSec > 0) {
      final parts = <String>[];
      if (rtMin > 0) parts.add("$rtMin Minute");
      if (rtSec > 0) parts.add("$rtSec Second");
      runningTime = parts.join(" ");
    }

    // Issue date
final rd = widget.data["date_release"]?.toString() ?? "";
final rm = widget.data["month_release"]?.toString() ?? "";
final ry = widget.data["year_release"]?.toString() ?? "";
releaseDate = (rd.isNotEmpty && rm.isNotEmpty && ry.isNotEmpty)
    ? "$rd/$rm/$ry"
    : "";
releaseDateFormatted = widget.data["release_date_formatted"]?.toString() ?? "";

    // ✅ FALLBACK: Extract genre/language from list API if details API doesn't have them
    final genresData = widget.data["genres"];
    if (genresData is Map) {
      final genreList = genresData["genre_list"];
      if (genreList is List) {
        final names = genreList
            .map((g) {
              if (g is Map) return g["name"]?.toString() ?? "";
              return "";
            })
            .where((n) => n.isNotEmpty)
            .toList();
        if (names.isNotEmpty) genre = names.join(", ");
      } else if (genresData["genre_line"] is String) {
        final line = genresData["genre_line"].toString();
        if (line.isNotEmpty) genre = line;
      }
    }

    final extractedLang = DataAdapter.extractLanguage(widget.data);
    if (extractedLang.isNotEmpty && extractedLang != "Unknown") {
      language = extractedLang;
    }

    fetchDetails();
  }

  String get starringShort {
    if (cast.isEmpty) return "";
    return "${cast.take(2).join(", ")}${cast.length > 2 ? " +${cast.length - 2}" : ""}";
  }

  /// ✅ Get formatted movie title for dubbed movies
  String _getMovieTitle() {
    // Check if it's a dubbed movie
    if (widget.data["dubbed_film_name"] != null) {
      final filmName = widget.data["dubbed_film_name"]?.toString() ?? name;
      final filmLanguage =
          widget.data["dubbed_film_language"]?.toString() ?? "";
      return "$filmName in $filmLanguage";
    }

    // Regular movie format
    return "${widget.data["film_name"] ?? name} in ${widget.data["film_lang"] ?? language}";
  }

  /// ✅ Check if current movie is dubbed
  bool _isDubbedMovie() {
    return widget.data["dubbed_film_name"] != null;
  }

  /// ✅ FORMAT TEXT: Add comma before "and"
  String _formatWithComma(dynamic data) {
    if (data == null) return "";

    String text;
    if (data is List) {
      // If it's a list, join items with comma
      text = data.map((item) => item.toString()).join(", ");
    } else {
      // If it's already a string, use as-is
      text = data.toString();
    }

    if (text.isEmpty) return text;

    // Replace " and " with ", and "
    return text.replaceAll(RegExp(r'\s+and\s+'), ', and ');
  }

  /// ✅ EXTRACT NAMES FROM COMPLEX OBJECTS
  String _extractNames(dynamic data) {
    if (data == null) return "";

    if (data is List) {
      final names = <String>[];
      for (final item in data) {
        if (item is Map) {
          // Extract name from object with 'name' field
          final name = item["name"]?.toString();
          if (name != null && name.isNotEmpty) {
            names.add(name);
          }
        } else if (item is String) {
          // If it's already a string, use it directly
          if (item.isNotEmpty) {
            names.add(item);
          }
        }
      }
      return names.join(", ");
    } else if (data is Map) {
      // Single object with name field
      return data["name"]?.toString() ?? "";
    } else if (data is String) {
      // Already a string
      return data;
    }

    return "";
  }

  List get exploreFive {
    final currentId = (widget.data["unique_id"] ?? widget.data["film_id"])
        ?.toString();

    final filtered = widget.exploreList.where((m) {
      final id = (m["unique_id"] ?? m["film_id"])?.toString();
      return id != null && id != currentId;
    }).toList();

    return filtered.isNotEmpty
        ? filtered.take(5).toList()
        : widget.exploreList.take(5).toList();
  }

  Future<void> fetchDetails() async {
    final id = widget.data["unique_id"] ?? widget.data["film_id"];
    if (id == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=$id",
        ),
      );

      if (res.statusCode != 200) {
        setState(() => loading = false);
        return;
      }

      // ✅ Strip PHP warnings before JSON parse
      final bodyStr = res.body.trim();
      final jsonStart = bodyStr.indexOf('{');
      if (jsonStart < 0) { setState(() => loading = false); return; }
      final raw = jsonDecode(bodyStr.substring(jsonStart));
      print("---- DETAILS API RESPONSE ----");
      print("Movie ID: $id");
      print("CBFC from DETAILS API:");
      print("cbfc_rating: ${raw["cbfc_rating"]}");
      print("cbfc_certificate_no: ${raw["cbfc_certificate_no"]}");
      print("cbfc_certificate_date: ${raw["cbfc_certificate_date"]}");
      print("cbfc_certificate_month: ${raw["cbfc_certificate_month"]}");
      print("cbfc_certificate_year: ${raw["cbfc_certificate_year"]}");
      print("-------------------------------");

      // 🔥 FETCH CBFC DATA
      // 🔥 FETCH CBFC DATA (DO NOT OVERWRITE LIST API DATA)

      if (raw["cbfc_rating"] != null &&
          raw["cbfc_rating"].toString().isNotEmpty) {
        cbfcRating = raw["cbfc_rating"].toString();
      }

      if (raw["cbfc_certificate_no"] != null &&
          raw["cbfc_certificate_no"].toString().isNotEmpty) {
        cbfcNumber = raw["cbfc_certificate_no"].toString();
      }

      final d = raw["cbfc_certificate_date"]?.toString() ?? "";
      final m = raw["cbfc_certificate_month"]?.toString() ?? "";
      final y = raw["cbfc_certificate_year"]?.toString() ?? "";

      if (d.isNotEmpty && m.isNotEmpty && y.isNotEmpty) {
        cbfcDate = "$d/$m/$y";
      }

      if (raw["trailers"] is List && raw["trailers"].isNotEmpty) {
        final t = raw["trailers"][0];

        final extractedId = DataAdapter.extractYoutubeId(t);

        if (extractedId != null && extractedId.length == 11) {
          trailerUrl = extractedId;
        } else {
          trailerUrl = null;
        }

        poster ??= t["youtube_image_url"];
      }

      final schemaRaw = raw["schema"];
      if (schemaRaw is String && schemaRaw.contains("{")) {
        for (final part in schemaRaw.split("</script>")) {
          final clean = part.replaceAll(RegExp(r'<script[^>]*>'), '').trim();
          if (!clean.startsWith("{")) continue;

          final schema = jsonDecode(clean);
          if (schema["@type"] != "Movie") continue;

          if (schema["genre"] is List) {
            genre = (schema["genre"] as List).join(", ");
          }

          if (schema["inLanguage"] is String) {
            language = schema["inLanguage"];
          }

          final dir = schema["director"];
          if (dir is Map && dir["name"] != null) {
            director = dir["name"];
          } else if (dir is List) {
            director = dir.map((d) => d["name"]).whereType<String>().join(", ");
          }

          final actors = schema["actor"];
          if (actors is List) {
            cast = actors.map((a) => a["name"]).whereType<String>().toList();
          } else if (actors is Map && actors["name"] != null) {
            cast = [actors["name"]];
          }
          break;
        }
      }

      // ✅ FALLBACK: film_at_a_glance + direct fields
      final glance = raw['film_at_a_glance'];
      if (genre.isEmpty) {
        final g = raw['film_genre']?.toString() ?? '';
        if (g.isNotEmpty) genre = g;
      }
      if (genre.isEmpty && glance is Map) {
        genre = glance['Genre']?.toString() ?? '';
      }
      if (language.isEmpty) {
        language = raw['film_language']?.toString() ?? '';
      }
      if (language.isEmpty && glance is Map) {
        language = glance['Language']?.toString() ?? '';
      }
      // youtube field as fallback trailer
      if (trailerUrl == null) {
        final yt = raw['youtube']?.toString() ?? '';
        if (yt.length == 11) trailerUrl = yt;
      }
      // poster from youtube field
      if (poster == null && trailerUrl != null) {
        poster = 'https://img.youtube.com/vi/$trailerUrl/hqdefault.jpg';
      }
      if (raw["release_date_formatted"] != null &&
          raw["release_date_formatted"].toString().isNotEmpty) {
        releaseDateFormatted = raw["release_date_formatted"].toString();
      }
    } catch (_) {}
    print("FINAL CBFC VALUES USED IN UI:");
    print("cbfcRating: $cbfcRating");
    print("cbfcNumber: $cbfcNumber");
    print("cbfcDate: $cbfcDate");
    print("=====================================");

    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xffD4AF37)),
            )
          : buildContent(),
    );
  }

  Widget buildContent() {
    final categoryRaw = widget.data["trailer_category"]?.toString() ?? DataAdapter.extractCategorySlug(widget.data);
    final isFullMovie = categoryRaw.toLowerCase().contains("full");

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              _getMovieTitle(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (poster != null)
                  Image.network(
                    poster!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.movie,
                            color: Colors.white30,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                        Colors.black.withOpacity(0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
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
                if (genre.isNotEmpty) infoRow("Genre", genre),
                if (releaseDateFormatted.isNotEmpty)
                  infoRow("Release on", releaseDateFormatted)
                else if (releaseDate.isNotEmpty)
                  infoRow("Release Date", releaseDate),
                if (language.isNotEmpty) infoRow("Language", language),
                if (director.isNotEmpty) infoRow("Director", director),
                if (cast.isNotEmpty)
                  GestureDetector(
                    onTap: showCastSheet,
                    child: infoRow("Starring", starringShort),
                  ),

                // ✅ FULL MOVIES API FIELDS
                if (widget.data["genre_list"] != null &&
                    widget.data["genre_list"].toString().isNotEmpty)
                  infoRow("Genre", widget.data["genre_list"]),
                if (_extractNames(widget.data["directors"]).isNotEmpty)
                  infoRow(
                    "Director",
                    _formatWithComma(_extractNames(widget.data["directors"])),
                  ),
                if (_extractNames(widget.data["producers"]).isNotEmpty)
                  infoRow(
                    "Producer",
                    _formatWithComma(_extractNames(widget.data["producers"])),
                  ),
                if (_extractNames(widget.data["lead_cast"]).isNotEmpty)
                  infoRow("Lead Cast", _extractNames(widget.data["lead_cast"])),

                /// ✅ MORE INFO TOGGLE
                if (!isFullMovie && (cbfcRating.isNotEmpty || cbfcNumber.isNotEmpty || cbfcDate.isNotEmpty || releaseDate.isNotEmpty || releaseDateFormatted.isNotEmpty || runningTime.isNotEmpty))
                  GestureDetector(
                    onTap: () => setState(() => _showMoreInfo = !_showMoreInfo),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "More Info",
                            style: const TextStyle(
                              color: Color(0xffD4AF37),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showMoreInfo
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xffD4AF37),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!isFullMovie && _showMoreInfo) ...[
                  if (cbfcRating.isNotEmpty) infoRow("CBFC Rating", cbfcRating),
                  if (cbfcNumber.isNotEmpty) infoRow("Certificate No", cbfcNumber),
                  if (cbfcDate.isNotEmpty) infoRow("Issue Date", cbfcDate),
                  if (runningTime.isNotEmpty) infoRow("Running Time", runningTime),
                ],
                const SizedBox(height: 26),

                const Text(
                  "Movies",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xffD4AF37),
                  ),
                ),
                const SizedBox(height: 12),
                trailerButton(),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: showReportSheet,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Report an issue",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: const Text(
              "Explore More Movies like this",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              itemCount: exploreFive.length,
              itemBuilder: (context, i) {
                final m = exploreFive[i];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: MovieTile(
                    id:
                        m["film_id"]?.toString() ??
                        m["unique_id"]?.toString() ??
                        "",
                    title: DataAdapter.extractTitle(m),
                    year: DataAdapter.extractYear(m),
                    posterOverride: DataAdapter.extractPoster(m),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(
                            data: m,
                            exploreList: widget.exploreList,
                          ),
                        ),
                      );
                    },
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
    final categoryRaw = widget.data["trailer_category"]?.toString() ??
        DataAdapter.extractCategorySlug(widget.data);
    
    // Split categories by comma
    final categories = categoryRaw
        .split(',')
        .map((cat) => cat.trim())
        .where((cat) => cat.isNotEmpty)
        .toList();

    if (categories.isEmpty) {
      categories.add("Trailer");
    }

    final uniqueCategories = categories.toSet().toList();

    final watchUrlStr = widget.data["youtube_watch_url"]?.toString() ??
        widget.data["film_watch_url"]?.toString() ??
        "";
    final hasWatchUrl = watchUrlStr.isNotEmpty;

    final trailerUrlStr = (trailerUrl != null && trailerUrl!.isNotEmpty)
        ? (trailerUrl!.length == 11 ? "https://www.youtube.com/watch?v=$trailerUrl" : trailerUrl!)
        : "";
    final hasTrailerUrl = trailerUrlStr.isNotEmpty;

    // A helper to determine the correct launch URL for each category
    Uri? getUrlForCategory(String cat) {
      if (cat.toLowerCase().contains("trailer")) {
        if (hasTrailerUrl) return Uri.parse(trailerUrlStr);
        if (hasWatchUrl) return Uri.parse(watchUrlStr);
      } else {
        if (hasWatchUrl) return Uri.parse(watchUrlStr);
        if (hasTrailerUrl) return Uri.parse(trailerUrlStr);
      }
      return null;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: uniqueCategories.map((cat) {
          final uri = getUrlForCategory(cat);
          if (uri == null) return const SizedBox.shrink();

          final displayCategory =
              (_isDubbedMovie() && cat.toLowerCase() == "movie")
                  ? "Dubbed Movie"
                  : cat;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: () async {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(220, 50),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                "Watch $displayCategory",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showCastSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Starring",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ...cast.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    c,
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showReportSheet() {
    final TextEditingController controller = TextEditingController();
    String issueType = "Wrong Information";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Report an Issue",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: issueType,
                dropdownColor: Colors.black,
                items: const [
                  DropdownMenuItem(
                    value: "Wrong Information",
                    child: Text("Wrong Information"),
                  ),
                  DropdownMenuItem(
                    value: "Trailer not playing",
                    child: Text("Trailer not playing"),
                  ),
                  DropdownMenuItem(
                    value: "Wrong Poster",
                    child: Text("Wrong Poster"),
                  ),
                  DropdownMenuItem(
                    value: "Other Issue",
                    child: Text("Other Issue"),
                  ),
                ],
                onChanged: (v) => issueType = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Describe the issue...",
                  filled: true,
                  fillColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await ReportService.submitReport(
                    movieId: widget.data["unique_id"] ?? widget.data["film_id"],
                    movieName: name,
                    issueType: issueType,
                    message: controller.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Submit Report"),
              ),
            ],
          ),
        );
      },
    );
  }
}