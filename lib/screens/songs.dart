import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'songs_detail.dart';

class LatestSongsScreen extends StatefulWidget {
  const LatestSongsScreen({super.key});

  @override
  State<LatestSongsScreen> createState() => _LatestSongsScreenState();
}

class _LatestSongsScreenState extends State<LatestSongsScreen> {
  List<dynamic> songs = [];
  bool isLoading = true;
  String? error;

  @override

  void initState() {
    super.initState();
    fetchSongs();
  }

  Future<void> fetchSongs() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.bollywoodproduct.com/api/songs/latest.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          songs = data['songs'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load songs';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: const Text(
          'Latest Songs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : error != null
              ? Center(
                  child: Text(error!,
                      style: const TextStyle(color: Colors.white54)),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _SongTile(song: songs[index]);
                  },
                ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Map<String, dynamic> song;

  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final filmName = song['film_name'] ?? '-';
    final year = song['year_release']?.toString() ?? '';
    final filmLabel = year.isNotEmpty ? '$filmName ($year)' : filmName;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50), // pill shape
        ),
        child: Row(
          children: [
            // Circle thumbnail
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xff2C2C2C), Color(0xff121212)],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: song['thumbnail'] != null &&
                        song['thumbnail'].toString().isNotEmpty
                    ? Image.network(
                        song['thumbnail'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.music_note,
                          color: Colors.white38,
                          size: 22,
                        ),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: Colors.white38,
                        size: 22,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Title + Language
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song['title'] ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song['language'] ?? '-'}  •  $filmLabel',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}