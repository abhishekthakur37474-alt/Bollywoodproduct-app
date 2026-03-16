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

    fetchDetails();

  }

  String get starringShort {
    if (cast.isEmpty) return "";
    return "${cast.take(2).join(", ")}${cast.length > 2 ? " +${cast.length - 2}" : ""}";
  }

  List get exploreFive {
    final currentId =
    (widget.data["unique_id"] ?? widget.data["film_id"])?.toString();

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
            "https://hindi.bollywoodproduct.com/api-film-details.php?unique_id=$id"),
      );

      if (res.statusCode != 200 || !res.body.trim().startsWith('{')) {
        setState(() => loading = false);
        return;
      }

      final raw = jsonDecode(res.body);
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

      if (raw["cbfc_rating"] != null && raw["cbfc_rating"].toString().isNotEmpty) {
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
          final clean =
          part.replaceAll(RegExp(r'<script[^>]*>'), '').trim();
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
            director =
                dir.map((d) => d["name"]).whereType<String>().join(", ");
          }

          final actors = schema["actor"];
          if (actors is List) {
            cast =
                actors.map((a) => a["name"]).whereType<String>().toList();
          } else if (actors is Map && actors["name"] != null) {
            cast = [actors["name"]];
          }
          break;
        }
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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              name,
              maxLines: 1,
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
                if (language.isNotEmpty) infoRow("Language", language),
                if (director.isNotEmpty) infoRow("Director", director),
                if (cast.isNotEmpty)
                  GestureDetector(
                    onTap: showCastSheet,
                    child: infoRow("Starring", starringShort),
                  ),

                /// ✅ CBFC UI
                if (cbfcRating.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 18),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cbfcRating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (cbfcNumber.isNotEmpty)
                          Text(
                            "Certificate No: $cbfcNumber",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        if (cbfcDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              cbfcDate,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 26),

                const Text(
                  "Trailers",
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
                      Icon(Icons.flag_outlined,
                          size: 16, color: Colors.redAccent),
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
              padding:
              const EdgeInsets.symmetric(horizontal: 22),
              itemCount: exploreFive.length,
              itemBuilder: (context, i) {
                final m = exploreFive[i];
                return Container(
                  width: 140,
                  margin:
                  const EdgeInsets.only(right: 12),
                  child: MovieTile(
                    id: m["unique_id"],
                    title: DataAdapter.extractTitle(m),
                    year: DataAdapter.extractYear(m),
                    posterOverride:
                    DataAdapter.extractPoster(m),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(
                            data: m,
                            exploreList:
                            widget.exploreList,
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
    if (trailerUrl == null || trailerUrl!.length != 11) {
      return Text(
        "No Trailers",
        style: TextStyle(color: Colors.grey.shade400),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: () async {
          final url = Uri.parse(
              "https://www.youtube.com/watch?v=$trailerUrl");

          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(
              horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "Watch Trailer",
          style:
          TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
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
      backgroundColor:
      const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
            top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                "Starring",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                  height: 16),
              ...cast.map(
                    (c) => Padding(
                  padding:
                  const EdgeInsets.only(
                      bottom: 10),
                  child: Text(
                    c,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      color:
                      Colors.white,
                    ),
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
    final TextEditingController
    controller =
    TextEditingController();
    String issueType =
        "Wrong Information";

    showModalBottomSheet(
      context: context,
      backgroundColor:
      const Color(0xff111111),
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
            top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                "Report an Issue",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(
                  height: 16),
              DropdownButtonFormField<
                  String>(
                value: issueType,
                dropdownColor:
                Colors.black,
                items: const [
                  DropdownMenuItem(
                      value:
                      "Wrong Information",
                      child: Text(
                          "Wrong Information")),
                  DropdownMenuItem(
                      value:
                      "Trailer not playing",
                      child: Text(
                          "Trailer not playing")),
                  DropdownMenuItem(
                      value:
                      "Wrong Poster",
                      child: Text(
                          "Wrong Poster")),
                  DropdownMenuItem(
                      value:
                      "Other Issue",
                      child: Text(
                          "Other Issue")),
                ],
                onChanged: (v) =>
                issueType = v!,
              ),
              const SizedBox(
                  height: 12),
              TextField(
                controller:
                controller,
                maxLines: 3,
                decoration:
                const InputDecoration(
                  hintText:
                  "Describe the issue...",
                  filled: true,
                  fillColor:
                  Colors.black,
                ),
              ),
              const SizedBox(
                  height: 16),
              ElevatedButton(
                onPressed:
                    () async {
                  await ReportService
                      .submitReport(
                    movieId:
                    widget.data[
                    "unique_id"] ??
                        widget.data[
                        "film_id"],
                    movieName:
                    name,
                    issueType:
                    issueType,
                    message:
                    controller
                        .text,
                  );
                  if (context
                      .mounted)
                    Navigator.pop(
                        context);
                },
                child: const Text(
                    "Submit Report"),
              ),
            ],
          ),
        );
      },
    );
  }
}
