// // import 'dart:convert';
// // import 'package:http/http.dart' as http;
// //
// // import 'home_cache.dart';
// // import '../services/ott_service.dart';
// //
// // class HomeService {
// //   static bool _loading = false;
// //
// //   static Future<void> loadHomeData() async {
// //     // ✅ ALREADY LOADED → SKIP
// //     if (HomeCache.loaded) {
// //       print("🟢 [HOME SERVICE] Cache already loaded, skipping");
// //       return;
// //     }
// //
// //     // ✅ PREVENT DOUBLE CALLS
// //     if (_loading) {
// //       print("🟡 [HOME SERVICE] Already loading, skipping");
// //       return;
// //     }
// //
// //     _loading = true;
// //     print("🟡 [HOME SERVICE] Fetching home data");
// //
// //     try {
// //       // 🔥 PARALLEL API CALLS (FAST)
// //       final results = await Future.wait([
// //         http.get(Uri.parse(
// //             "https://hindi.bollywoodproduct.com/api-latest-movies.php")),
// //         http.get(Uri.parse(
// //             "https://hindi.bollywoodproduct.com/api-upcoming-movies.php")),
// //         http.get(Uri.parse(
// //             "https://hindi.bollywoodproduct.com/api-full-movies.php")),
// //       ]);
// //
// //       final latestRes = results[0];
// //       final upcomingRes = results[1];
// //       final fullRes = results[2];
// //
// //       // ✅ SAFE JSON PARSING
// //       if (latestRes.statusCode == 200 &&
// //           latestRes.body.trim().startsWith("{")) {
// //         HomeCache.latest =
// //             jsonDecode(latestRes.body)["movies"] ?? [];
// //         print("🟢 [HOME SERVICE] Latest=${HomeCache.latest.length}");
// //       }
// //
// //       if (upcomingRes.statusCode == 200 &&
// //           upcomingRes.body.trim().startsWith("{")) {
// //         HomeCache.upcoming =
// //             jsonDecode(upcomingRes.body)["movies"] ?? [];
// //         print("🟢 [HOME SERVICE] Upcoming=${HomeCache.upcoming.length}");
// //       }
// //
// //       if (fullRes.statusCode == 200 &&
// //           fullRes.body.trim().startsWith("{")) {
// //         HomeCache.full =
// //             jsonDecode(fullRes.body)["movies"] ?? [];
// //         print("🟢 [HOME SERVICE] Full=${HomeCache.full.length}");
// //       }
// //
// // // 🔥 PREFETCH + CACHE OTT
// //       final ottList = await OttService.fetchOtt();
// //       HomeCache.ott = ottList;
// //       print("🟢 [HOME SERVICE] OTT=${HomeCache.ott.length}");
// //
// //
// //       HomeCache.loaded = true;
// //       print("🟢 [HOME SERVICE] Home data cached successfully");
// //     } catch (e) {
// //       print("🔴 [HOME SERVICE] Error: $e");
// //     }
// //
// //     _loading = false;
// //   }
// // }
//
//
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'home_cache.dart';
// import '../services/ott_service.dart';
//
// class HomeService {
//   static bool _loading = false;
//
//   // 🔥 STEP 1: CRITICAL (fast)
//   static Future<void> loadCriticalData() async {
//     print("🟡 [HOME SERVICE] Loading CRITICAL data");
//
//     try {
//       final latestRes = await http.get(
//         Uri.parse("https://hindi.bollywoodproduct.com/api-latest-movies.php"),
//       );
//
//       if (latestRes.statusCode == 200 &&
//           latestRes.body.trim().startsWith("{")) {
//         HomeCache.latest =
//             jsonDecode(latestRes.body)["movies"] ?? [];
//
//         print("🟢 Latest loaded = ${HomeCache.latest.length}");
//       }
//     } catch (e) {
//       print("🔴 Critical load error: $e");
//     }
//   }
//
//   // 🔥 STEP 2: FULL background
//   static Future<void> loadRemainingData() async {
//     if (_loading) return;
//
//     _loading = true;
//     print("🟡 [HOME SERVICE] Loading REMAINING");
//
//     try {
//       final results = await Future.wait([
//         http.get(Uri.parse(
//             "https://hindi.bollywoodproduct.com/api-upcoming-movies.php")),
//         http.get(Uri.parse(
//             "https://hindi.bollywoodproduct.com/api-full-movies.php")),
//       ]);
//
//       final upcomingRes = results[0];
//       final fullRes = results[1];
//
//       if (upcomingRes.statusCode == 200 &&
//           upcomingRes.body.trim().startsWith("{")) {
//         HomeCache.upcoming =
//             jsonDecode(upcomingRes.body)["movies"] ?? [];
//       }
//
//       if (fullRes.statusCode == 200 &&
//           fullRes.body.trim().startsWith("{")) {
//         HomeCache.full =
//             jsonDecode(fullRes.body)["movies"] ?? [];
//       }
//
//       // OTT in background
//       final ott = await OttService.fetchOtt();
//       HomeCache.ott = ott;
//
//       print("🟢 Remaining loaded");
//     } catch (e) {
//       print("🔴 Remaining error: $e");
//     }
//
//     _loading = false;
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_cache.dart';
import '../services/ott_service.dart';
import '../services/dubbed_service.dart';

class HomeService {
  static bool _loading = false;

  static Future<void> loadAllHomeData() async {
    if (_loading) {
      print("🟡 Already loading");
      return;
    }

    _loading = true;
    print("🟡 [HOME SERVICE] Loading ALL data");

    try {
      /// 🔥 PARALLEL API CALLS (FASTEST)
      final results = await Future.wait([
        http.get(
          Uri.parse("https://hindi.bollywoodproduct.com/api-latest-movies.php"),
        ),
        http.get(
          Uri.parse(
            "https://hindi.bollywoodproduct.com/api-upcoming-movies.php",
          ),
        ),
        http.get(
          Uri.parse("https://hindi.bollywoodproduct.com/api-full-movies.php"),
        ),
        OttService.fetchOtt(),
        DubbedService.fetchDubbed(),
      ]);

      final latestRes = results[0] as http.Response;
      final upcomingRes = results[1] as http.Response;
      final fullRes = results[2] as http.Response;
      final ottList = results[3] as List;
      final dubbedList = results[4] as List;

      if (latestRes.statusCode == 200 &&
          latestRes.body.trim().startsWith("{")) {
        HomeCache.latest = jsonDecode(latestRes.body)["movies"] ?? [];
      }

      if (upcomingRes.statusCode == 200 &&
          upcomingRes.body.trim().startsWith("{")) {
        HomeCache.upcoming = jsonDecode(upcomingRes.body)["movies"] ?? [];
      }

      if (fullRes.statusCode == 200 && fullRes.body.trim().startsWith("{")) {
        HomeCache.full = jsonDecode(fullRes.body)["movies"] ?? [];
      }

      HomeCache.ott = ottList;
      HomeCache.dubbed = dubbedList;

      print("🟢 ALL home data loaded");
    } catch (e) {
      print("🔴 Load error: $e");
    }

    _loading = false;
  }
}
