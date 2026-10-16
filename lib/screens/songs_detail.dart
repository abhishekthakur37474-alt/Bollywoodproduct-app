import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'common.dart';

class SongDetailScreen extends StatefulWidget {
  final Map<String, dynamic> song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _filmLabel() {
    final name = widget.song['film_name'] ?? '';
    final year = widget.song['year_release']?.toString() ?? '';
    if (name.isEmpty) return '-';
    return year.isNotEmpty ? '$name ($year)' : name;
  }

  String? _filmMeta() {
    final year = widget.song['year_release']?.toString() ?? '';
    final lang = widget.song['film_language']?.toString() ?? '';
    final parts = [if (year.isNotEmpty) year, if (lang.isNotEmpty) lang];
    if (parts.isEmpty) return null;
    return parts.join('  •  ');
  }

  String? _nonEmpty(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _listField(dynamic val) {
    if (val == null) return null;
    if (val is List) {
      final joined = val
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .join(', ');
      return joined.isEmpty ? null : joined;
    }
    return _nonEmpty(val);
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final singers   = _listField(song['singers']);
    final genres    = _listField(song['genres']);
    final language  = _nonEmpty(song['language']);
    final musicDir  = _listField(song['music_directors']);
    final lyricist  = _listField(song['lyricists']);
    final filmMeta  = _filmMeta() ?? _nonEmpty(song['film_name']);
    final hasYoutube = (song['youtube_id'] ?? '').toString().isNotEmpty;
    final youtubeUrl = 'https://www.youtube.com/watch?v=${song['youtube_id']}';

    final goldGradient = [
      const Color(0xffD4AF37).withOpacity(0.8),
      const Color(0xff8A7322),
    ];

    final metaRows = <_MetaEntry>[
       if (_nonEmpty(song['film_name']) != null) _MetaEntry('Film', _filmLabel()),
      if (language  != null) _MetaEntry('Song Language',  language),
      if (genres    != null) _MetaEntry('Genre',          genres),
      if (singers   != null) _MetaEntry('Singer',         singers),
      if (musicDir  != null) _MetaEntry('Music Director', musicDir),
      if (lyricist  != null) _MetaEntry('Lyricist',       lyricist),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF0F0F0F),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: hasYoutube ? () => _launchUrl(youtubeUrl) : null,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    song['thumbnail'] != null &&
                            song['thumbnail'].toString().isNotEmpty
                        ? Image.network(
                            song['thumbnail'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xff1C1C1C)),
                          )
                        : Container(color: const Color(0xff1C1C1C)),

                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xFF0F0F0F)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    if (hasYoutube)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20, right: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.white70, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Click to Watch',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '-',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: "Watch Video",
                          gradient: LinearGradient(colors: goldGradient),
                          onTap: () {
                            if (hasYoutube) _launchUrl(youtubeUrl);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.movie_filter,
                          label: "Film Page",
                          gradient: const LinearGradient(
                            colors: [Color(0xff434343), Color(0xff000000)],
                          ),
                          onTap: () {
                            final uniqueId =
                                widget.song['film_unique_id']?.toString().trim() ?? "";
                            if (uniqueId.isEmpty) {
                              print("🔴 [SONG TAP] film_unique_id empty, film=${widget.song['film_name']}");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Film ID missing in this song's API data")),
                              );
                              return;
                            }
                            print("🟢 [SONG TAP] → unique_id=$uniqueId");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommonScreen(
                                  uniqueId: uniqueId,
                                  language: widget.song['language']?.toString(),
                                  onlyFullTrailers: false,
                                  exploreList: const [],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  for (int i = 0; i < metaRows.length; i++) ...[
                    _DetailRow(label: metaRows[i].label, value: metaRows[i].value),
                    if (i < metaRows.length - 1) const _Divider(),
                  ],
                  const SizedBox(height: 28),

                  const Text(
                    'Explore Non-Stop',
                    style: TextStyle(
                      color: Color(0xffD4AF37),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── More songs from same film ──────────────────────────
                  if ((song['more_songs_from_same_film'] as List?)?.isNotEmpty == true) ...[
                    _RelatedSongsSection(
                      title: 'More Songs from ${song['film_name'] ?? 'This Film'}',
                      parentSong: song,
                      songs: List<Map<String, dynamic>>.from(
                        (song['more_songs_from_same_film'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── From same Singer ──────────────────────────────────
                  for (final singerGroup in (song['more_songs_by_same_singer'] as List? ?? [])) ...[
                    if (singerGroup is Map) ...[
                      () {
                        final singerName = singerGroup['singer_name']?.toString() ?? 'Singer';
                        final singerSongs = (singerGroup['songs'] as List?)
                            ?.where((s) => s is Map)
                            .map((s) => Map<String, dynamic>.from(s as Map))
                            .toList() ?? [];
                        if (singerSongs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RelatedSongsSection(
                              title: 'From $singerName',
                              songs: singerSongs,
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      }(),
                    ],
                  ],

                  // ── From same Music Director ───────────────────────────
                  for (final mdGroup in (song['more_songs_by_same_music_director'] as List? ?? [])) ...[
                    if (mdGroup is Map) ...[
                      () {
                        final mdName = mdGroup['music_director_name']?.toString() ?? 'Music Director';
                        final mdSongs = (mdGroup['songs'] as List?)
                            ?.where((s) => s is Map)
                            .map((s) => Map<String, dynamic>.from(s as Map))
                            .toList() ?? [];
                        if (mdSongs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RelatedSongsSection(
                              title: 'From $mdName',
                              songs: mdSongs,
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      }(),
                    ],
                  ],

                  // ── From same Lyricist ─────────────────────────────────
                  for (final lyGroup in (song['more_songs_by_same_lyricist'] as List? ?? [])) ...[
                    if (lyGroup is Map) ...[
                      () {
                        final lyName = lyGroup['lyricist_name']?.toString() ?? 'Lyricist';
                        final lySongs = (lyGroup['songs'] as List?)
                            ?.where((s) => s is Map)
                            .map((s) => Map<String, dynamic>.from(s as Map))
                            .toList() ?? [];
                        if (lySongs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RelatedSongsSection(
                              title: 'From $lyName',
                              songs: lySongs,
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      }(),
                    ],
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Related Songs Section
// ─────────────────────────────────────────────────────────────────────────────

class _RelatedSongsSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> songs;
  final Map<String, dynamic>? parentSong;

  const _RelatedSongsSection({required this.title, required this.songs, this.parentSong});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = parentSong != null ? {
                'film_id':        parentSong!['film_id'],
                'film_name':      parentSong!['film_name'],
                'year_release':   parentSong!['year_release'],
                'language':       parentSong!['language'],
                'film_unique_id': parentSong!['film_unique_id'],
                ...songs[i],
              } : songs[i];
              return _RelatedSongTile(song: s);
            },
          ),
        ),
      ],
    );
  }
}

class _RelatedSongTile extends StatelessWidget {
  final Map<String, dynamic> song;

  const _RelatedSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final thumb = song['thumbnail']?.toString() ?? '';
    final title = song['title']?.toString() ?? '-';
    final filmName = song['film_name']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)),
      ),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: thumb.isNotEmpty
                  ? Image.network(
                      thumb,
                      width: 110,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (filmName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                filmName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 110,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xff2C2C2C), Color(0xff121212)],
        ),
      ),
      child: const Icon(Icons.music_note, color: Colors.white24, size: 28),
    );
  }
}

class _MetaEntry {
  final String label;
  final String value;
  const _MetaEntry(this.label, this.value);
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.07), height: 1);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}