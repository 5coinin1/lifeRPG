import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guild_model.dart';
import '../models/hero_model.dart';
import '../models/guardian_model.dart';
import '../models/boss_raid_model.dart';
import '../services/guild_service.dart';
import '../services/boss_raid_service.dart';

/// Chi tiết guild cho người CHƯA tham gia (hoặc view detail từ Dashboard).
/// 3 tabs: Overview | Events | Members
class GuildDetailScreen extends StatefulWidget {
  final String guildId;
  final String? currentMemberId;
  final bool? isParent;

  const GuildDetailScreen({
    super.key,
    required this.guildId,
    this.currentMemberId,
    this.isParent,
  });

  @override
  State<GuildDetailScreen> createState() => _GuildDetailScreenState();
}

class _GuildDetailScreenState extends State<GuildDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  GuildModel? _guild;
  List<HeroModel> _heroes = [];
  List<GuardianModel> _guardians = [];
  bool _loading = true;
  bool _requestSent = false;

  final _db = FirebaseFirestore.instance;
  final BossRaidService _raidService = BossRaidService();
  late final Stream<GuildEventState?> _eventStream =
      _raidService.latestEventStream(widget.guildId);
  late final Stream<List<Map<String, dynamic>>> _leaderboardStream =
      _raidService.leaderboardStream(widget.guildId);
  String? _currentUid;
  String? _memberId;
  bool _isParent = false;
  bool _isPending = false;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _memberId = widget.currentMemberId ?? _currentUid;
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final guildDoc = await _db.collection('guilds').doc(widget.guildId).get();
    if (!guildDoc.exists || !mounted) return;
    final guild = GuildModel.fromDoc(guildDoc);

    // check role
    if (_memberId != null) {
      if (widget.isParent != null) {
        _isParent = widget.isParent!;
      } else if (_currentUid != null) {
        final acct = await _db.collection('accounts').doc(_currentUid).get();
        _isParent = acct.data()?['role'] == 'guardian';
      }
      _isPending = _isParent
          ? guild.pendingGuardianIds.contains(_memberId)
          : guild.pendingHeroIds.contains(_memberId);
      _isMember = _isParent
          ? guild.guardianIds.contains(_memberId)
          : guild.heroIds.contains(_memberId);
    }

    // Load members
    List<HeroModel> heroes = [];
    if (guild.heroIds.isNotEmpty) {
      final snap = await _db
          .collection('heroes')
          .where(FieldPath.documentId, whereIn: guild.heroIds)
          .get();
      heroes = snap.docs.map((d) => HeroModel.fromDoc(d)).toList();
    }
    List<GuardianModel> guardians = [];
    if (guild.guardianIds.isNotEmpty) {
      final snap = await _db
          .collection('guardians')
          .where(FieldPath.documentId, whereIn: guild.guardianIds)
          .get();
      guardians = snap.docs.map((d) => GuardianModel.fromDoc(d)).toList();
    }

    if (mounted) {
      setState(() {
        _guild = guild;
        _heroes = heroes;
        _guardians = guardians;
        _loading = false;
      });
    }
  }

  Future<void> _sendJoinRequest() async {
    if (_memberId == null) return;
    setState(() => _requestSent = true);
    try {
      await GuildService().requestToJoin(
        guildId: widget.guildId,
        guardianId: _isParent ? _memberId : null,
        heroId: !_isParent ? _memberId : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent! Waiting for Guild Master approval.'),
            backgroundColor: Color(0xFF388E3C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requestSent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C17),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _guild?.name.toUpperCase() ?? 'GUILD INFO',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFFED65B),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFED65B),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'EVENTS'),
            Tab(text: 'MEMBERS'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            )
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildOverview(),
                      _buildEvents(),
                      _buildMembers(),
                    ],
                  ),
                ),
                if (!_isMember) _buildJoinBar(),
              ],
            ),
    );
  }

  // ── TAB 1: Overview ──────────────────────────────────────────────────────────
  Widget _buildOverview() {
    final g = _guild!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero banner
          Container(
            width: double.infinity,
            color: const Color(0xFF1C1C17),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFED65B),
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    _iconFor(g.iconName),
                    color: const Color(0xFFFED65B),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        color: const Color(0xFF8F7100),
                        child: Text(
                          g.tag.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats
          _statRow(Icons.leaderboard, 'GUILD LEVEL', 'LVL ${g.level}'),
          _statRow(Icons.star_border, 'GUILD EXP', _fmt(g.exp)),
          _statRow(Icons.group, 'GUARDIANS', '${g.guardianIds.length}'),
          _statRow(
            Icons.person,
            'HEROES',
            '${g.heroIds.length}',
            isLast: false,
          ),
          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFEBE8DF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT THIS GUILD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F7663),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  g.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1C17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF1C1C17),
            width: isLast ? 2 : 1,
          ),
        ),
        color: const Color(0xFFF6F3EA),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF735C00)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7F7663),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Events (active event, read-only — không có nút ENTER RAID) ─────────
  Widget _buildEvents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT EVENTS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<GuildEventState?>(
            stream: _eventStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
                  ),
                );
              }
              final state = snap.data;
              if (state == null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE8DF),
                    border: Border.all(color: const Color(0xFF1C1C17), width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      'No active events right now.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF77574D),
                      ),
                    ),
                  ),
                );
              }
              if (state.isCompleted) return _buildEventEndedInfoCard(state);
              return _buildBossEventInfoCard(state);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBossEventInfoCard(GuildEventState state) {
    final maxHp = state.bossMaxHp;
    final hp = state.currentHp.clamp(0, maxHp);
    final percent = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C17),
        border: Border.all(color: const Color(0xFFBA1A1A), width: 3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOSS RAID',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA1A1A),
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: const Color(0xFFBA1A1A),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.bossName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOSS HP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$hp / $maxHp  (${(percent * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            decoration: BoxDecoration(border: Border.all(color: Colors.white)),
            child: Stack(
              children: [
                Container(color: const Color(0xFF4D4635)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percent,
                  child: Container(color: const Color(0xFFBA1A1A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!_isMember)
            const Center(
              child: Text(
                'Join the guild to participate!',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventEndedInfoCard(GuildEventState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C17),
        border: Border.all(color: const Color(0xFF2E7D32), width: 3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EVENT ENDED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66E07A),
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: const Color(0xFF2E7D32),
                child: const Text(
                  'CLEARED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '🏆 ${state.bossName} has been defeated!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'RESULTS (DAMAGE)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          _buildResultBoard(),
        ],
      ),
    );
  }

  Widget _buildResultBoard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _leaderboardStream,
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return const Text(
            'No contribution data.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          );
        }
        return Column(
          children: List.generate(entries.length, (i) {
            final e = entries[i];
            final rank = i + 1;
            final medal = rank == 1
                ? '🥇'
                : rank == 2
                ? '🥈'
                : rank == 3
                ? '🥉'
                : '$rank.';
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: rank <= 3
                    ? const Color(0xFF2A2A22)
                    : const Color(0xFF232019),
                border: Border.all(
                  color: rank == 1 ? const Color(0xFFD4AF37) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      medal,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e['name'] as String? ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${e['damage'] ?? 0} DMG',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // ── TAB 3: Members ─────────────────────────────────────────────────────────────
  Widget _buildMembers() {
    final g = _guild!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'GUARDIANS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F7663),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._guardians.map(
          (grd) => _memberTile(
            name: grd.displayName,
            subtitle: grd.uid == g.ownerId ? '★ GUILD MASTER' : 'GUARDIAN',
            subtitleColor: grd.uid == g.ownerId
                ? const Color(0xFF8F7100)
                : const Color(0xFF4D4635),
            isMaster: grd.uid == g.ownerId,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'HEROES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7F7663),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ..._heroes.map(
          (h) => _memberTile(
            name: h.displayName,
            subtitle:
                '${h.characterPath}  ·  LVL ${h.level}  ·  ${h.title.toUpperCase()}',
            subtitleColor: const Color(0xFF4D4635),
          ),
        ),
        if (_heroes.isEmpty && _guardians.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'No members yet.',
                style: TextStyle(
                  color: Color(0xFF7F7663),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _memberTile({
    required String name,
    required String subtitle,
    required Color subtitleColor,
    bool isMaster = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMaster ? const Color(0xFF1C1C17) : const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isMaster
                  ? const Color(0xFF8F7100)
                  : const Color(0xFFEBE8DF),
              border: Border.all(color: const Color(0xFF1C1C17)),
            ),
            child: Icon(
              Icons.person,
              color: isMaster ? Colors.white : const Color(0xFF7F7663),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isMaster ? Colors.white : const Color(0xFF1C1C17),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMaster ? const Color(0xFFFED65B) : subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── JOIN bar ──────────────────────────────────────────────────────────────────
  Widget _buildJoinBar() {
    final pending = _isPending || _requestSent;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C17),
        border: Border(top: BorderSide(color: Color(0xFFFED65B), width: 2)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: pending ? null : _sendJoinRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: pending
                ? const Color(0xFF4D4635)
                : const Color(0xFFFED65B),
            foregroundColor: pending ? Colors.white60 : const Color(0xFF1C1C17),
            disabledBackgroundColor: const Color(0xFF4D4635),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            pending ? 'REQUEST PENDING...' : 'REQUEST TO JOIN GUILD',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String n) {
    switch (n) {
      case 'book':
        return Icons.menu_book;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.shield;
    }
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return '$v';
  }
}
