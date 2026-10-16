import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';
import '../utils/paginated_list.dart';
import '../widgets/movie_list_tile.dart';
import 'common.dart';

class LatestOttPage extends StatefulWidget {
  const LatestOttPage({super.key});

  @override
  State<LatestOttPage> createState() => _LatestOttPageState();
}

class _LatestOttPageState extends State<LatestOttPage>
    with AutomaticKeepAliveClientMixin {
  static List _allFilms = [];

  Future<List> fetch() async {
    // 🔥 FIX: home_service already fetches api-ott-latest-movies.php in
    // _loadExtraData() and stores it in HomeCache.ottLatest. Pehle ye page
    // us cache ko ignore karke apna alag fresh API call marta tha —
    // isliye tab open karte hi phir se network wait hota tha jab ke
    // data already ready tha. Ab cache pehle check hota hai.
    if (HomeCache.ottLatest.isNotEmpty) {
      print("🟢 [LATEST OTT] Using HomeCache.ottLatest: ${HomeCache.ottLatest.length}");
      _allFilms = HomeCache.ottLatest;
      return _allFilms;
    }

    if (_allFilms.isNotEmpty) {
      print("🟢 [LATEST OTT] Using local cache ${_allFilms.length} films");
      return _allFilms;
    }

    print("🟡 [LATEST OTT] Cache empty, fetching from API...");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-ott-latest-movies.php"),
    );

    if (res.statusCode != 200) return [];

    final raw = jsonDecode(res.body);
    final list = raw["films"] ?? [];
    _allFilms = list;
    HomeCache.ottLatest = list; // ✅ cache save so next time no wait
    print("🟢 [LATEST OTT] Fetched ${list.length} films");
    return list;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PaginatedList(
      fetch: fetch,
      pageSize: 15,
      builder: (m) {
        final title = m["film_name"]?.toString() ?? "Untitled";
        final language = m["ott_language_name"]?.toString() ?? "";
        final poster = m["film_image"]?.toString();
        final uniqueId =
            (m["film_unique_id"] ?? m["film_id"] ?? m["ott_id"] ?? "")
                .toString();

        return MovieListTile(
          id: uniqueId,
          title: title,
          language: language,
          posterOverride: poster,
          onTap: () {
            if (uniqueId.isEmpty) {
              print("🔴 [LATEST OTT TAP] unique_id empty, film=$title");
              return;
            }
            print("🟢 [LATEST OTT] Tapped: $title → unique_id=$uniqueId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommonScreen(
                  uniqueId: uniqueId,
                  posterUrl: poster,
                  language: language,
                  onlyFullTrailers: false,
                  ottPlatform: m["ott_platform"]?.toString(),
                  ottLink: m["ott_link"]?.toString(),
                  exploreList: _allFilms,
                ),
              ),
            );
          },
        );
      },
    );
  }
}