import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/report_service.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_tile.dart';
import 'celebrity_detail_page.dart';

class CommonScreen extends StatefulWidget {
  final String uniqueId;
  final String? posterUrl;
  final String? language;
  final List exploreList;
  final bool onlyFullTrailers; // true=Full Movies ("full" word wale), false=sab trailers (Upcoming/Dubbed/Latest)
  final bool isDubbed; // true=Watch buttons dubbed_films[] se banenge (Watch Movie in {language})
  final String? ottPlatform; // OTT: "Watch on {ottPlatform}" → opens ottLink direct
  final String? ottLink;

  const CommonScreen({
    super.key,
    required this.uniqueId,
    this.posterUrl,
    this.language,
    this.exploreList = const [],
    this.onlyFullTrailers = true,
    this.isDubbed = false,
    this.ottPlatform,
    this.ottLink,
  });

  @override
  State<CommonScreen> createState() => _CommonScreenState();
}

class _CommonScreenState extends State<CommonScreen> {
  bool _loading = true;
  String _error = "";

  String _filmName = "";
  String _genre = "";
  String _releaseDate = "";
  String _cbfc = "";
  String _runtime = "";
  String _leadCast = "";
  List<Map<String, String>> _leadCastList = []; // 🔥 tappable lead cast: name + profile_unique_id
  String _directors = "";
  String _producers = "";
  String _fallbackPoster = ""; // 🔥 api-film.php["film_image_url"] — only used if widget.posterUrl empty
  List<Map<String, String>> _watchOptions = []; // {category, language, url}

  Map _rawJson = {}; // full decoded response, for JSON viewer

  static const Set<String> _usedJsonKeys = {
    "name", "genre_list", "release_date_month_year",
    "cbfc_rating", "running_time_minutes", "running_time_seconds",
    "lead_casts_list", "directors_list", "producers_list",
    "trailer_category", "trailer_lanaguage", "teaser", "trailer_url",
    "ott_platform", "ott_link",
  };

  @override
  void initState() {
    super.initState();
    _fetchFilmDetail();
  }

  String _joinNames(dynamic list) {
    if (list is! List) return "";
    return list
        .map((e) => e is Map ? (e["name"]?.toString() ?? "") : "")
        .where((n) => n.isNotEmpty)
        .join(", ");
  }

  String _formatRuntime(dynamic minutes, dynamic seconds) {
    final totalMin = int.tryParse(minutes?.toString() ?? "") ?? 0;
    final sec = int.tryParse(seconds?.toString() ?? "") ?? 0;
    if (totalMin == 0 && sec == 0) return "";
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(h)}:${two(m)}:${two(sec)}";
  }

  Future<void> _fetchFilmDetail() async {
    final url =
        "https://www.bollywoodproduct.com/language-subdomain/api-film.php?unique_id=${widget.uniqueId}";
    print("🟡 [COMMON] GET $url");
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        setState(() {
          _error = "ERROR: status ${res.statusCode}";
          _loading = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      _rawJson = decoded is Map ? decoded : {};

      final film = decoded["film"] is Map ? decoded["film"] as Map : {};
      final genres = decoded["genres"] is Map ? decoded["genres"] as Map : {};
      final rating =
          decoded["film_rating"] is Map ? decoded["film_rating"] as Map : {};
      final leadCasts =
          decoded["lead_casts"] is Map ? decoded["lead_casts"] as Map : {};
      final directors =
          decoded["directors"] is Map ? decoded["directors"] as Map : {};
      final producers =
          decoded["producers"] is Map ? decoded["producers"] as Map : {};
      final trailers =
          decoded["trailers"] is List ? decoded["trailers"] as List : [];
      final ottFilm =
          decoded["ott_film"] is List ? decoded["ott_film"] as List : [];

      // 🟡 DEBUG: raw common-page fields, unique_id se aaya api-film.php response
      print("🟡 [COMMON DEBUG] uniqueId=${widget.uniqueId}");
      print("🟡 [COMMON DEBUG] film_name: ${film["name"]}");
      print("🟡 [COMMON DEBUG] genre_list: ${genres["genre_list"]}");
      print("🟡 [COMMON DEBUG] release_date_month_year: ${film["release_date_month_year"]}");
      print("🟡 [COMMON DEBUG] cbfc_rating: ${rating["cbfc_rating"]}");
      print("🟡 [COMMON DEBUG] running_time_minutes: ${rating["running_time_minutes"]}");
      print("🟡 [COMMON DEBUG] running_time_seconds: ${rating["running_time_seconds"]}");
      print("🟡 [COMMON DEBUG] lead_casts_list: ${leadCasts["lead_casts_list"]}");
      print("🟡 [COMMON DEBUG] directors_list: ${directors["directors_list"]}");
      print("🟡 [COMMON DEBUG] producers_list: ${producers["producers_list"]}");
      print("🟡 [COMMON DEBUG] trailers[] raw (count=${trailers.length}): $trailers");
      print("🟡 [COMMON DEBUG] ott_film[] raw (count=${ottFilm.length}): $ottFilm");
      print("🟡 [COMMON DEBUG] widget.ottPlatform=${widget.ottPlatform}  widget.ottLink=${widget.ottLink}");

      // Watch buttons: SABHI sections (Full/Dubbed/Latest/Upcoming/OTT) ke liye
      // uniform trailers[] node se hi bante hain — koi "full" word filter nahi,
      // koi dubbed_films branch nahi.
      final List<Map<String, String>> watchList = trailers
          .whereType<Map>()
          .map((t) {
        final teaser = t["teaser"]?.toString() ?? "";
        final ytUrl = teaser.isNotEmpty
            ? "https://www.youtube.com/watch?v=$teaser"
            : (t["trailer_url"]?.toString() ?? "");
        return {
          "category": t["trailer_category"]?.toString() ?? "Watch",
          "language": t["trailer_lanaguage"]?.toString() ?? "",
          "url": ytUrl,
        };
      }).where((e) => (e["url"] ?? "").isNotEmpty).toList();

      print("🟡 [COMMON DEBUG] watchList from trailers[] (count=${watchList.length}): $watchList");

      // 🔥 FLAG: agar ott_film[] me ott_platform + ott_link mile,
      // to "Watch on {ott_platform}" option bhi watchList me add hoga.
      final List<Map<String, String>> ottWatchList = ottFilm
          .whereType<Map>()
          .map((o) {
        final platform = o["ott_platform_name"]?.toString().trim() ?? "";
        final link = o["ott_link"]?.toString().trim() ?? "";
        return {
          "category": platform.isNotEmpty ? "on $platform" : "",
          "language": "",
          "url": link,
        };
      })
          .where((e) => (e["category"] ?? "").isNotEmpty && (e["url"] ?? "").isNotEmpty)
          .toList();

      print("🟡 [COMMON DEBUG] ottWatchList from ott_film[] (count=${ottWatchList.length}): $ottWatchList");

      watchList.addAll(ottWatchList);

      // 🔥 Home-tap se aaya ottPlatform/ottLink (widget prop) bhi merge —
      // ab sab "Watch" ke andar hi ek sath aayenge, alag button nahi.
      if ((widget.ottPlatform ?? "").isNotEmpty && (widget.ottLink ?? "").isNotEmpty) {
        watchList.add({
          "category": "on ${widget.ottPlatform}",
          "language": "",
          "url": widget.ottLink!,
        });
        print("🟡 [COMMON DEBUG] added widget-level ott button: on ${widget.ottPlatform} → ${widget.ottLink}");
      }

      // 🔥 DEDUPE: "on {platform}" wale entries platform-name se dedupe
      // (kyunki ott_film[] aur widget.ottLink ka url string exact match
      // nahi hota kabhi kabhi — format thoda alag ho sakta). Trailers
      // wale url se dedupe (same category multiple languages me valid hai).
      final seenUrls = <String>{};
      final seenOttPlatforms = <String>{};
      final dedupedWatchList = watchList.where((e) {
        final url = e["url"] ?? "";
        final category = (e["category"] ?? "").toLowerCase().trim();
        if (url.isEmpty) return false;

        if (category.startsWith("on ")) {
          if (seenOttPlatforms.contains(category)) return false;
          seenOttPlatforms.add(category);
          return true;
        }

        if (seenUrls.contains(url)) return false;
        seenUrls.add(url);
        return true;
      }).toList();

      print("🟢 [COMMON DEBUG] FINAL dedupedWatchList (count=${dedupedWatchList.length}): $dedupedWatchList");

      setState(() {
        _filmName = film["name"]?.toString() ?? "";
        _genre = _joinNames(genres["genre_list"]);
        _releaseDate = film["release_date_month_year"]?.toString() ?? "";
        _cbfc = rating["cbfc_rating"]?.toString() ?? "";
        _runtime = _formatRuntime(
          rating["running_time_minutes"],
          rating["running_time_seconds"],
        );
        _leadCast = _joinNames(leadCasts["lead_casts_list"]);
        _leadCastList = (leadCasts["lead_casts_list"] is List)
            ? (leadCasts["lead_casts_list"] as List)
                .whereType<Map>()
                .map((e) => {
                      "name": e["name"]?.toString() ?? "",
                      "profile_unique_id":
                          e["profile_unique_id"]?.toString() ?? "",
                    })
                .where((e) => (e["name"] ?? "").isNotEmpty)
                .toList()
            : [];
        _directors = _joinNames(directors["directors_list"]);
        _producers = _joinNames(producers["producers_list"]);
        _fallbackPoster = (decoded["film_image_url"] ?? film["film_image_url"] ?? "")
            .toString()
            .trim();
        _watchOptions = dedupedWatchList
            .map((e) => {
                  "category": e["category"] ?? "",
                  "language": e["language"] ?? "",
                  "url": e["url"] ?? "",
                })
            .toList();
        _loading = false;
      });
    } catch (e) {
      print("🔴 [COMMON] error: $e");
      setState(() {
        _error = "ERROR: $e";
        _loading = false;
      });
    }
  }

  // 🔥 Lead cast tap → api-cast-list.php?profile_unique_id={id} se fetch karke
  // CelebrityDetailPage open karo (same design jo Celebrity section me hai).
  Future<void> _openCelebrity(String profileUniqueId, String name) async {
    if (profileUniqueId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xffD4AF37)),
      ),
    );

    try {
      final url =
          "https://www.bollywoodproduct.com/api-cast-list.php?profile_unique_id=$profileUniqueId";
      print("🟡 [LEAD CAST TAP] GET $url");
      final res = await http.get(Uri.parse(url));

      if (mounted) Navigator.pop(context); // close loading dialog

      if (res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      final list = decoded is Map ? decoded["data"] : null;
      if (list is! List || list.isEmpty) {
        print("🔴 [LEAD CAST TAP] no data for profile_unique_id=$profileUniqueId");
        return;
      }

      final celeb = Map.from(list.first as Map);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CelebrityDetailPage(celeb: celeb)),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading dialog on error
      print("🔴 [LEAD CAST TAP] error: $e");
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List get _exploreFive {
    final list = widget.exploreList.where((m) {
      final id = (m["film_unique_id"] ?? m["film_id"] ?? m["unique_id"] ?? m["ott_id"])?.toString();
      return id != null && id != widget.uniqueId;
    }).toList();
    return (list.isNotEmpty ? list : widget.exploreList).take(5).toList();
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xff1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  void _showWatchOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.45, // 🔒 45% of screen
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text("Watch Options",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _watchOptions.length,
                  itemBuilder: (_, i) {
                    final opt = _watchOptions[i];
                    final label = (opt["language"] ?? "").isNotEmpty
                        ? "Watch ${opt["category"]} in ${opt["language"]}"
                        : "Watch ${opt["category"]}";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final url = opt["url"] ?? "";
                            Navigator.pop(context);
                            if (url.isNotEmpty) _launch(url);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(label,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReport() {
    String issueType = "Wrong Information";
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: StatefulBuilder(
          builder: (ctx, set) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text("Report an Issue",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                value: issueType,
                dropdownColor: const Color(0xff1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Issue Type"),
                items: const [
                  DropdownMenuItem(value: "Wrong Information", child: Text("Wrong Information")),
                  DropdownMenuItem(value: "Movie not playing", child: Text("Movie not playing")),
                  DropdownMenuItem(value: "Wrong Poster", child: Text("Wrong Poster")),
                  DropdownMenuItem(value: "Other Issue", child: Text("Other Issue")),
                ],
                onChanged: (v) => set(() => issueType = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco("Describe the issue..."),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await ReportService.submitReport(
                      movieId: widget.uniqueId,
                      movieName: _filmName,
                      issueType: issueType,
                      message: ctrl.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Submit Report",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJsonView() {
    String pretty;
    try {
      pretty = const JsonEncoder.withIndent("  ").convert(_rawJson);
    } catch (_) {
      pretty = _rawJson.toString();
    }

    // 🟡 DEBUG: full api-film.php response console me print
    print("🟡 [COMMON JSON] language-subdomain/api-film.php full response:");
    print(pretty);

    final lines = pretty.split("\n");

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111111),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Raw JSON Data",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(width: 12, height: 12, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  const Text("= used on this screen",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText.rich(
                    TextSpan(
                      children: lines.map((line) {
                        final match = RegExp(r'^\s*"([A-Za-z0-9_]+)"\s*:').firstMatch(line);
                        final key = match?.group(1);
                        final isUsed = key != null && _usedJsonKeys.contains(key);
                        return TextSpan(
                          text: "$line\n",
                          style: TextStyle(
                            fontFamily: "monospace",
                            fontSize: 12,
                            height: 1.5,
                            color: isUsed ? Colors.redAccent : Colors.grey.shade400,
                            fontWeight: isUsed ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cbfcBadge(String rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 110,
            child: Text("CBFC Certificate",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xffD4AF37),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(rating,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // 🔥 Lead Cast row — same layout as _infoRow but har naam tappable hai,
  // tap karne pe api-cast-list.php se fetch karke CelebrityDetailPage khulta hai.
  Widget _leadCastRow() {
    if (_leadCastList.isEmpty) return _infoRow("Featuring", _leadCast);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 110,
            child: Text("Featuring",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (int i = 0; i < _leadCastList.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: Builder(builder: (_) {
                      final pid = _leadCastList[i]["profile_unique_id"] ?? "";
                      final hasId = pid.toString().trim().isNotEmpty;
                      return GestureDetector(
                        onTap: hasId
                            ? () => _openCelebrity(pid, _leadCastList[i]["name"] ?? "")
                            : null,
                        child: Text(
                          "${_leadCastList[i]["name"]}${i != _leadCastList.length - 1 ? "," : ""}",
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                            decoration: hasId
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor: const Color(0xffD4AF37),
                            decorationThickness: 2,
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xff1A1A1A),
        child: const Center(child: Icon(Icons.movie, color: Color(0xffD4AF37), size: 64)),
      );

  Widget _buildAppBar() {
    // 🔥 FLAG: pehle previous-section wala posterUrl (widget prop) use hoga.
    // Wo empty ho (seedha uniqueId se aaya ho, koi section se nahi), tabhi
    // api-film.php ka fallback "film_image_url" use hoga.
    final effectivePoster = (widget.posterUrl != null && widget.posterUrl!.isNotEmpty)
        ? widget.posterUrl!
        : _fallbackPoster;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: effectivePoster.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(effectivePoster, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder()),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.language ?? "").isNotEmpty ? "$_filmName in ${widget.language}" : _filmName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xffD4AF37),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),

          _infoRow("Language", widget.language ?? ""),
          _infoRow("Genre", _genre),
          _infoRow("Release Date", _releaseDate),
          if (_cbfc.isNotEmpty) _cbfcBadge(_cbfc),
          _infoRow("Running Time", _runtime),
          _leadCastRow(),
          _infoRow("Director", _directors),
          _infoRow("Producer", _producers),

          const SizedBox(height: 28),

          if (_watchOptions.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 22),
                label: const Text("Watch",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _showWatchOptions,
              ),
            ),

          const SizedBox(height: 12),

          /*
          // View JSON — debug
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.data_object, color: Colors.white70, size: 18),
              label: const Text("View JSON", style: TextStyle(color: Colors.white70, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showJsonView,
            ),
          ),

          const SizedBox(height: 12),
          */

          // Report button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined, color: Color(0xffD4AF37), size: 18),
              label: const Text("Report & Issues", style: TextStyle(color: Color(0xffD4AF37), fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xffD4AF37)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showReport,
            ),
          ),

          const SizedBox(height: 36),

          // Explore More
          if (_exploreFive.isNotEmpty) ...[
            const Text(
              "Explore More Movies Like This",
              style: TextStyle(color: Color(0xffD4AF37), fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _exploreFive.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final m = _exploreFive[i];
                  final explLang = DataAdapter.extractDubbedLanguage(m); // auto-fallback to extractLanguage
                  final explYear = DataAdapter.extractYear(m);
                  final explSubtitle = [explLang, explYear].where((s) => s.isNotEmpty).join(" • ");
                  final explId = (m["film_unique_id"] ?? m["film_id"] ?? m["unique_id"] ?? m["ott_id"])?.toString() ?? "";
                  return MovieTile(
                    id: explId,
                    title: DataAdapter.extractTitle(m),
                    year: explSubtitle,
                    posterOverride: DataAdapter.extractPoster(m),
                    onTap: () => Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => CommonScreen(
                          uniqueId: explId,
                          posterUrl: DataAdapter.extractPoster(m),
                          language: explLang,
                          exploreList: widget.exploreList,
                          onlyFullTrailers: widget.onlyFullTrailers,
                          isDubbed: widget.isDubbed,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xff0F0F0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xffD4AF37))),
      );
    }
    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xff0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(child: Text(_error, style: const TextStyle(color: Colors.white))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }
}