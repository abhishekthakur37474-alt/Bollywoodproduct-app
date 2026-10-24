import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/auth_service.dart';
import 'quiz_service.dart';

const _gold = Color(0xffD4AF37);
const _card = Color(0xff1A1A1A);
const _silver = Color(0xffC0C0C0);
const _bronze = Color(0xffCD7F32);

String _pts(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

Color _rankColor(int? r) {
  switch (r) {
    case 1:
      return _gold;
    case 2:
      return _silver;
    case 3:
      return _bronze;
    default:
      return const Color(0xff333333);
  }
}

class QuizLeaderboardScreen extends StatefulWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  State<QuizLeaderboardScreen> createState() => _QuizLeaderboardScreenState();
}

class _QuizLeaderboardScreenState extends State<QuizLeaderboardScreen> {
  static const _periods = [
    ('today', 'Today'),
    ('week', 'This Week'),
    ('month', 'This Month'),
    ('year', 'This Year'),
  ];

  String _period = 'today';
  final Map<String, LeaderboardData> _cache = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    QuizService.scoreVersion.addListener(_refresh);
    AuthService.bollyUserId.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    QuizService.scoreVersion.removeListener(_refresh);
    AuthService.bollyUserId.removeListener(_refresh);
    super.dispose();
  }

  // all cached boards become stale after quiz save / login-logout
  void _refresh() {
    _cache.clear();
    _load();
  }

  Future<void> _load() async {
    final period = _period;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await QuizService.fetchLeaderboard(period);
      if (!mounted) return;
      setState(() {
        _cache[period] = d;
        if (_period == period) _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load leaderboard. Please check your internet.';
        _loading = false;
      });
    }
  }

  void _selectPeriod(String p) {
    if (p == _period) return;
    setState(() => _period = p);
    if (!_cache.containsKey(p)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _cache[_period];
    final me = data?.me;
    final loggedIn = QuizService.userId != null;
    // viewPadding = system inset only (does not grow with extendBody)
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    final showMe = loggedIn && me != null;

    return Column(
      children: [
        _buildTabs(),
        Expanded(
          child: RefreshIndicator(
            color: _gold,
            backgroundColor: _card,
            onRefresh: _load,
            child: _buildBody(data, showMe),
          ),
        ),
        // fixed "Your Rank" card: list scrolls only up to this
        if (showMe)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildMeCard(me!),
          ),
        // gap above the navbar
        SizedBox(height: bottomSafe + 12 + 64 + 22), // navbar = 64 + 12 pad, +22 gap
      ],
    );
  }

  // ---------------- tabs ----------------
  Widget _buildTabs() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22D4AF37)),
        ),
        child: Row(
          children: _periods.map((p) {
            final sel = p.$1 == _period;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _selectPeriod(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? _gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.$2.replaceFirst('This ', ''),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? const Color(0xff111111) : Colors.white60,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------- body ----------------
  Widget _buildBody(LeaderboardData? data, bool hasMeCard) {
    final bottomPad = hasMeCard ? 12.0 : 20.0;

    if (data == null) {
      if (_loading) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator(color: _gold)),
          ],
        );
      }
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 110),
        children: [
          _emptyBox(
            icon: Icons.wifi_off_rounded,
            title: _error ?? 'Something went wrong',
            sub: 'Pull down to try again',
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xff111111),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    final rows = data.rows;
    if (rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
        children: [
          _emptyBox(
            icon: Icons.emoji_events_outlined,
            title: 'No scores yet for this period',
            sub: 'Be the first to climb the board!',
          ),
        ],
      );
    }

    final showPodium = rows.length >= 3;
    final rest = showPodium ? rows.sublist(3) : rows;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPad),
      children: [
        if (showPodium) ...[
          _buildPodium(rows.take(3).toList()),
          const SizedBox(height: 18),
        ],
        for (final e in rest) _row(e),
      ],
    );
  }

  Widget _emptyBox(
      {required IconData icon, required String title, required String sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: _gold),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------- podium ----------------
  Widget _buildPodium(List<LeaderboardEntry> top) {
    // order on screen: 2nd, 1st, 3rd
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _podiumSlot(top[1], 52, 56)),
        Expanded(child: _podiumSlot(top[0], 68, 78)),
        Expanded(child: _podiumSlot(top[2], 52, 44)),
      ],
    );
  }

  Widget _podiumSlot(LeaderboardEntry e, double avatar, double stand) {
    final c = _rankColor(e.rank);
    final isMe = e.userId == QuizService.userId;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e.rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedChampion,
              size: 22,
              color: _gold,
              strokeWidth: 1.6,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 2),
            boxShadow: e.rank == 1
                ? [BoxShadow(color: c.withValues(alpha: 0.45), blurRadius: 14)]
                : null,
          ),
          child: _Avatar(url: e.picture, name: e.name, size: avatar),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isMe ? '${e.name} (You)' : e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_pts(e.points)} pts',
          style: const TextStyle(
              color: _gold, fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          height: stand,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.withValues(alpha: 0.35), c.withValues(alpha: 0.05)],
            ),
            border: Border.all(color: c.withValues(alpha: 0.5)),
          ),
          child: Text(
            '${e.rank}',
            style: TextStyle(
                color: c, fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // ---------------- list row ----------------
  Widget _row(LeaderboardEntry e) {
    final isMe = e.userId == QuizService.userId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0x22D4AF37) : _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? _gold : const Color(0x22FFFFFF),
          width: isMe ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: e.rank, size: 28),
          const SizedBox(width: 10),
          _Avatar(url: e.picture, name: e.name, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${e.name} (You)' : e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.correct}/${e.attempted} correct',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _pts(e.points),
            style: const TextStyle(
                color: _gold, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ---------------- my rank (pinned) ----------------
  Widget _buildMeCard(LeaderboardEntry me) {
    final ranked = me.rank != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xff141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold, width: 1.2),
        boxShadow: [
          BoxShadow(
              color: _gold.withValues(alpha: 0.18),
              blurRadius: 14,
              spreadRadius: 1),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ranked
              ? _RankBadge(rank: me.rank, size: 32, forceGold: true)
              : const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: 26,
                  color: _gold,
                  strokeWidth: 1.5,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Rank',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  ranked
                      ? '${me.correct}/${me.attempted} correct'
                      : 'Play a quiz to get ranked',
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Text(
            '${_pts(me.points)} pts',
            style: const TextStyle(
                color: _gold, fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ---------------- small widgets ----------------
class _RankBadge extends StatelessWidget {
  final int? rank;
  final double size;
  final bool forceGold;
  const _RankBadge({required this.rank, required this.size, this.forceGold = false});

  @override
  Widget build(BuildContext context) {
    final c = forceGold && (rank ?? 99) > 3 ? _gold : _rankColor(rank);
    final dark = c == _gold || c == _silver || c == _bronze;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      child: Text(
        '${rank ?? '-'}',
        style: TextStyle(
          color: dark ? const Color(0xff111111) : Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: const Color(0xff2A2A2A),
      child: Text(
        initial,
        style: TextStyle(
            color: _gold, fontSize: size * 0.42, fontWeight: FontWeight.w800),
      ),
    );

    return ClipOval(
      child: url.isEmpty
          ? fallback
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (_, child, p) => p == null ? child : fallback,
            ),
    );
  }
}