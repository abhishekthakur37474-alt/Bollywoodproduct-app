import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/report_service.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_tile.dart';

class CommonDetailScreen extends StatelessWidget {
  final Map data;
  final List exploreList;
  final bool isDubbed;
  final bool isUpcoming;
  final bool isLatest;
  final bool isOtt;

  const CommonDetailScreen({
    super.key,
    required this.data,
    required this.exploreList,
    this.isDubbed = false,
    this.isUpcoming = false,
    this.isLatest = false,
    this.isOtt = false,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DATA GETTERS — mapped per API source
  // ─────────────────────────────────────────────────────────────────────────

  // 🎬 ALL APIs → data["film_name"]
  // Fallback: DataAdapter.extractTitle (handles older/dubbed shape)
  String get _filmName =>
      data["film_name"]?.toString() ?? DataAdapter.extractTitle(data);

  // 🌐 ALL APIs → data["film_lang"]
  // e.g. "Hindi", "English", "Telugu"
  // Fallback: DataAdapter.extractLanguage
  String get _language =>
      data["film_lang"]?.toString().trim() ?? DataAdapter.extractLanguage(data);

  // 📅 Upcoming API only → data["year_release"]
  // Not shown in UI currently; kept for future use
  String get _year => data["year_release"]?.toString() ?? "";

  // 🎭 Genre — multiple API shapes handled:
  //   • Upcoming API    → data["genres"]["genre_line"]  (String)
  //                     → data["genres"]["genre_list"]  (List<{name}>)
  //   • Full/Latest/All → data["genre_list"]            (flat String)
  //     e.g. "Animation, Mystery Drama, Adventure"
  String get _genre {
    final genres = data["genres"];
    if (genres is Map) {
      final line = genres["genre_line"]?.toString().trim() ?? "";
      if (line.isNotEmpty) return line;
      final list = genres["genre_list"];
      if (list is List && list.isNotEmpty) {
        return list.map((g) => g["name"]?.toString() ?? "").where((n) => n.isNotEmpty).join(", ");
      }
    }
    // OTT API → data["genres"] is a flat List<{id, name, alias}>
    if (genres is List && genres.isNotEmpty) {
      return genres.map((g) => g["name"]?.toString() ?? "").where((n) => n.isNotEmpty).join(", ");
    }
    // Full/Latest/All movies API → flat key
    return data["genre_list"]?.toString().trim() ?? "";
  }

  // 🎤 Cast — multiple API shapes handled:
  //   • Dubbed API      → data["lead_cast_list"]  (flat String)
  //   • Upcoming API    → data["lead_cast_line"]  (flat String)
  //   • Upcoming API    → data["lead_cast"]        (List<{name}>)
  //   • Full/Latest/All → data["lead_cast"]        (flat String)
  //     e.g. "Nina Herzog, Yuri Lowenthal, ..."
  String get _cast {
    final pre = data["lead_cast_list"]?.toString().trim() ?? "";
    if (pre.isNotEmpty) return pre;
    final line = data["lead_cast_line"]?.toString().trim() ?? "";
    if (line.isNotEmpty) return line;

    final raw = data["lead_cast"];
    if (raw is List) {
      final names = raw
          .map((c) => c["name"]?.toString() ?? "")
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isEmpty) return "";
      if (names.length == 1) return names.first;
      return "${names.sublist(0, names.length - 1).join(", ")} and ${names.last}";
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final names = raw.split(",").map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
      if (names.length == 1) return names.first;
      return "${names.sublist(0, names.length - 1).join(", ")} and ${names.last}";
    }
    return "";
  }

  // 🎬 ALL APIs → data["directors"]  (flat String, may be empty)
  String get _director => data["directors"]?.toString().trim() ?? "";

  // 🎬 ALL APIs → data["producers"]  (flat String, may be empty)
  String get _producer => data["producers"]?.toString().trim() ?? "";

  // 📅 ALL APIs → data["release_date_formatted"]
  // e.g. "27 Mar 2018"
  // Hidden for upcoming movies (isUpcoming flag)
  String get _releaseDate {
    final formatted = data["release_date_formatted"]?.toString().trim() ?? "";
    if (formatted.isNotEmpty) return DataAdapter.formatReleaseDate(formatted);
    // Latest Movies API → date_release / month_release / year_release
    final d = data["date_release"]?.toString().trim() ?? "";
    final m = data["month_release"]?.toString().trim() ?? "";
    final y = data["year_release"]?.toString().trim() ?? "";
    if (d.isNotEmpty && m.isNotEmpty && y.isNotEmpty) {
      return DataAdapter.formatReleaseDate("$d/$m/$y");
    }
    return "";
  }

  // ⏱️ Running Time — Latest Movies API
  //   • running_time_minutes / running_time_seconds
  //   • fallback: cbfc_running_time_minutes / cbfc_running_time_seconds
  String get _runningTime {
    int min = int.tryParse(data["running_time_minutes"]?.toString() ?? "") ?? 0;
    int sec = int.tryParse(data["running_time_seconds"]?.toString() ?? "") ?? 0;
    if (min == 0 && sec == 0) {
      min = int.tryParse(data["cbfc_running_time_minutes"]?.toString() ?? "") ?? 0;
      sec = int.tryParse(data["cbfc_running_time_seconds"]?.toString() ?? "") ?? 0;
    }
    if (min == 0 && sec == 0) return "";
    final hh = min ~/ 60;
    final mm = min % 60;
    final parts = <String>[];
    if (hh > 0) parts.add("$hh Hour${hh > 1 ? 's' : ''}");
    if (mm > 0) parts.add("$mm Minute${mm > 1 ? 's' : ''}");
    if (sec > 0) parts.add("$sec Second${sec > 1 ? 's' : ''}");
    return parts.join(" ");
  }

  // 🔞 Upcoming/Latest/OTT → data["cbfc_rating"]
  // e.g. "U", "UA", "A", "UA16+"
  String get _cbfc => data["cbfc_rating"]?.toString().trim() ?? "";
  String get _cbfcCertNo => data["cbfc_certificate_no"]?.toString().trim() ?? "";

  // 📺 OTT API only → data["ott_platform"]
  // e.g. "Netflix", "Prime Video"
  String get _ottPlatform => data["ott_platform"]?.toString().trim() ?? "";

  // 🖼️ ALL APIs → data["film_image_url"]
  // e.g. "https://img.youtube.com/vi/y0Xttbt74gU/0.jpg"
  // Fallback: DataAdapter.extractPoster (handles older shape)
  String? get _poster =>
      data["film_image_url"]?.toString().trim().isNotEmpty == true
          ? data["film_image_url"].toString()
          : DataAdapter.extractPoster(data);

  // ▶️ Watch URL — priority order:
  //   1. data["film_watch_url"]                  (direct watch URL, any API)
  //   2. trailers[0]["youtube_watch_url"]         (Full Movies API → trailers list)
  //   3. data["youtube_watch_url"]               (flat fallback, older APIs)
  String? get _primaryUrl {
    final w = data["film_watch_url"]?.toString().trim() ?? "";
    if (w.isNotEmpty) return w;
    final trailers = _trailersList;
    if (trailers.isNotEmpty) {
      final y = trailers.first["youtube_watch_url"]?.toString().trim() ?? "";
      if (y.isNotEmpty) return y;
    }
    final y = data["youtube_watch_url"]?.toString().trim() ?? "";
    return y.isNotEmpty ? y : null;
  }

  // 📺 Full Movies API → data["trailers"] (List)
  // Each entry: {
  //   "category":          "Full Movie"
  //   "language":          "English"
  //   "teaser":            "y0Xttbt74gU"        (YouTube video ID)
  //   "watch_url":         "https://bollywoodproduct.com/.../watch-full-movie/english"
  //   "upload_date":       "13-06-2026"
  //   "youtube_watch_url": "https://www.youtube.com/watch?v=y0Xttbt74gU"
  // }
  // Used to generate per-language "Watch" buttons in bottom sheet
  List<Map> get _trailersList {
    final raw = data["trailers"];
    if (raw is List) return raw.whereType<Map>().toList();
    return [];
  }

  // 📺 Older/Dubbed API fallback → data["trailer_category"]
  // Flat comma-separated string e.g. "Hindi,Telugu"
  // Used only when trailers[] list is absent
  List<String> get _trailerCategories {
    final raw = data["trailer_category"]?.toString().trim() ?? "";
    if (raw.isEmpty) return [];
    return raw.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  // 🔍 Explore section — filters current movie out of exploreList, takes 5
  // exploreList passed from parent page (e.g. FullMoviesPage._allFullMovies)
  // Uses data["film_id"] or data["unique_id"] for dedup
  List get _exploreFive {
    final cid = (data["film_id"] ?? data["unique_id"])?.toString();
    final f = exploreList.where((m) {
      final id = (m["film_id"] ?? m["unique_id"])?.toString();
      return id != null && id != cid;
    }).toList();
    return (f.isNotEmpty ? f : exploreList).take(5).toList();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showWatchOptions(BuildContext context) {
    final trailers = _trailersList;
    // fallback: if no trailers list, use old category/primaryUrl path
    final categories = _trailerCategories;

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
        child: Column(
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
            const Text(
              "Watch Options",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // ── Full Movies API: trailers[] list → one button per entry ──
            // Label: "$category in $lang" e.g. "Full Movie in English"
            // URL:   trailer["youtube_watch_url"] → fallback trailer["watch_url"]
            if (trailers.isNotEmpty)
              ...trailers.map((trailer) {
                final category = trailer["category"]?.toString().trim() ?? "Full Movie";
                final lang = trailer["language"]?.toString().trim() ?? "";
                final ytUrl = trailer["youtube_watch_url"]?.toString().trim() ?? "";
                final watchUrl = trailer["watch_url"]?.toString().trim() ?? "";
                final url = ytUrl.isNotEmpty ? ytUrl : (watchUrl.isNotEmpty ? watchUrl : null);
                final label = lang.isNotEmpty ? "$category in $lang" : category;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                      label: Text(
                        label,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: url != null
                          ? () {
                              Navigator.pop(context);
                              _launch(url);
                            }
                          : null,
                    ),
                  ),
                );
              })

            // ── Fallback: older/dubbed API → flat trailer_category string ──
            // All buttons share single _primaryUrl
            else if (categories.isNotEmpty)
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                    label: Text(
                      () {
                        final tCat = data["trailer_category"]?.toString().trim() ?? "";
                        final tLang = data["trailer_lanaguage"]?.toString().trim() ?? "";
                        if (tCat.isNotEmpty && tLang.isNotEmpty) return "Watch $tCat in $tLang";
                        if (tCat.isNotEmpty) return "Watch $tCat";
                        return _language.isNotEmpty ? "Watch in $_language" : "Watch $cat";
                      }(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (_primaryUrl != null) _launch(_primaryUrl!);
                    },
                  ),
                ),
              ))

            // ── Fallback: single watch URL (any API with film_watch_url or youtube_watch_url) ──
            else if (_primaryUrl != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                  label: Text(_language.isNotEmpty ? "Watch in $_language" : "Watch Movie",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _launch(_primaryUrl!);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showReport(BuildContext context) {
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
                    // Report uses film_id (Full/Latest/All) or unique_id (Dubbed/Upcoming)
                    await ReportService.submitReport(
                      movieId: data["film_id"] ?? data["unique_id"],
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

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xff1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        // Poster: data["film_image_url"] — ALL APIs
        background: _poster != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(_poster!, fit: BoxFit.cover,
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

  Widget _placeholder() => Container(
        color: const Color(0xff1A1A1A),
        child: const Center(child: Icon(Icons.movie, color: Color(0xffD4AF37), size: 64)),
      );

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title: data["film_name"] — ALL APIs
          // OTT → "Movie Name (Year)"
          Text(
            isOtt
                ? (_year.isNotEmpty ? "$_filmName ($_year)" : _filmName)
                : (_language.isNotEmpty ? "$_filmName in $_language" : _filmName),
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xffD4AF37),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 20),

          // Info rows — keys per API noted in getters above
          if (_genre.isNotEmpty) _infoRow("Genre", _genre),             // data["genre_list"] or data["genres"]
          if (_language.isNotEmpty) _infoRow("Language", _language),   // data["film_lang"]
          if (_cast.isNotEmpty)
            _infoRow(isUpcoming ? "Starring" : "Starring", _cast),    // data["lead_cast*"]
          if (_releaseDate.isNotEmpty) _infoRow("Release Date", _releaseDate), // data["release_date_formatted"]
          if (_director.isNotEmpty) _infoRow("Director", _director),   // data["directors"]
          if (_producer.isNotEmpty) _infoRow("Producer", _producer),   // data["producers"]
          if ((isUpcoming || isLatest || isOtt) && _cbfc.isNotEmpty) ...[      // data["cbfc_rating"]
            const SizedBox(height: 6),
            _cbfcBadge(_cbfc),
          ],

          if (_runningTime.isNotEmpty) _infoRow("Running Time", _runningTime), // Latest API

          const SizedBox(height: 28),

          // Watch button
          // OTT → "Watch on {ott_platform}" → launches data["ott_link"]
          if (isOtt && _primaryUrl != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.ondemand_video, color: Colors.white, size: 22),
                label: Text(
                  _ottPlatform.isNotEmpty ? "Watch on $_ottPlatform" : "Watch Now",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _launch(_primaryUrl!),
              ),
            )

          // Watch button — visible when any URL exists (_primaryUrl != null)
          // Opens _showWatchOptions bottom sheet with per-trailer buttons
          else if (_primaryUrl != null)
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
                onPressed: () => _showWatchOptions(context),
              ),
            ),

          const SizedBox(height: 12),

          // Report button — uses data["film_id"] or data["unique_id"]
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined, color: Color(0xffD4AF37), size: 18),
              label: const Text("Report & Issues",
                  style: TextStyle(color: Color(0xffD4AF37), fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xffD4AF37)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showReport(context),
            ),
          ),

          const SizedBox(height: 36),

          // Explore More — uses exploreList from parent page
          // IDs: data["film_id"] (Full/Latest/All) or data["unique_id"] (Dubbed)
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
                  final explLang = isDubbed
                      ? DataAdapter.extractDubbedLanguage(m)
                      : DataAdapter.extractLanguage(m);
                  final explYear = DataAdapter.extractYear(m);
                  final explSubtitle = [explLang, explYear]
                      .where((s) => s.isNotEmpty)
                      .join(" • ");
                  return MovieTile(
                    id: (m["film_id"] ?? m["unique_id"])?.toString() ?? "",
                    title: DataAdapter.extractTitle(m),
                    year: explSubtitle,
                    posterOverride: DataAdapter.extractPoster(m),
                    onTap: () => Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => CommonDetailScreen(data: m, exploreList: exploreList),
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
            child: Text(
              rating,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
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
            child: Text(value,
                style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}