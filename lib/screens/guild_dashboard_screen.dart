import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/guild_model.dart';
import '../models/guild_quest_model.dart';
import '../models/boss_raid_model.dart';
import '../services/boss_raid_service.dart';
import '../services/guild_service.dart';
import 'guild_detail_screen.dart';
import 'guild_pending_screen.dart';
import 'boss_raid_screen.dart';

/// Dashboard guild — giao diện khác nhau theo role.
class GuildDashboardScreen extends StatefulWidget {
  final String guildId;
  final bool isParent;
  final String? currentMemberId;
  final VoidCallback? onLeave; // để Entry Screen reload sau khi rời guild
  final VoidCallback? onOpenTasks;
  const GuildDashboardScreen({
    super.key,
    required this.guildId,
    this.isParent = true,
    this.currentMemberId,
    this.onLeave,
    this.onOpenTasks,
  });

  @override
  State<GuildDashboardScreen> createState() => _GuildDashboardScreenState();
}

class _GuildDashboardScreenState extends State<GuildDashboardScreen> {
  int _tab = 0;
  GuildModel? _guild;
  List<GuildQuestModel> _quests = [];
  Map<String, String> _heroGuardianIds = {};
  bool _loading = true;
  String? _uid;
  bool _isOwner = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _guildSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _questSub;
  final TextEditingController _chatMsgCtrl = TextEditingController();
  String? _displayName;
  final BossRaidService _raidService = BossRaidService();
  late final Stream<GuildEventState?> _eventStream =
      _raidService.latestEventStream(widget.guildId);
  late final Stream<List<Map<String, dynamic>>> _leaderboardStream =
      _raidService.leaderboardStream(widget.guildId);

  @override
  void initState() {
    super.initState();
    _uid = widget.currentMemberId ?? FirebaseAuth.instance.currentUser?.uid;
    _fetchCurrentUserDetails();
    _listenRealtime();
  }

  void _fetchCurrentUserDetails() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc(_uid)
          .get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _displayName = doc.data()?['displayName'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatMsgCtrl.text.trim();
    if (text.isEmpty || _uid == null) return;

    _chatMsgCtrl.clear();

    final db = FirebaseFirestore.instance;
    final collectionName = widget.isParent
        ? 'council_messages'
        : 'fellowship_messages';

    try {
      await db
          .collection('guilds')
          .doc(widget.guildId)
          .collection(collectionName)
          .add({
            'senderId': _uid,
            'senderName': _displayName ?? 'Anonymous',
            'content': text,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void _listenRealtime() {
    final db = FirebaseFirestore.instance;
    _guildSub = db.collection('guilds').doc(widget.guildId).snapshots().listen((
      guildDoc,
    ) async {
      if (!guildDoc.exists || !mounted) return;
      final guild = GuildModel.fromDoc(guildDoc);
      final heroGuardianIds = <String, String>{};
      for (final heroId in guild.heroIds) {
        final heroDoc = await db.collection('heroes').doc(heroId).get();
        final guardianId = heroDoc.data()?['guardianId'] as String?;
        if (guardianId != null && guardianId.isNotEmpty) {
          heroGuardianIds[heroId] = guardianId;
        }
      }

      if (mounted) {
        setState(() {
          _guild = guild;
          _heroGuardianIds = heroGuardianIds;
          _isOwner = guild.ownerId == _uid;
          _loading = false;
        });
      }
    });

    _questSub = db
        .collection('guild_quests')
        .where('guildId', isEqualTo: widget.guildId)
        .snapshots()
        .listen((snapshot) {
          final quests = snapshot.docs
              .map((d) => GuildQuestModel.fromDoc(d))
              .toList();
          quests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (mounted) {
            setState(() {
              _quests = quests;
              _loading = false;
            });
          }
        });
  }

  Future<void> _load() async {
    final db = FirebaseFirestore.instance;
    final guildDoc = await db.collection('guilds').doc(widget.guildId).get();
    if (!guildDoc.exists || !mounted) return;
    final guild = GuildModel.fromDoc(guildDoc);

    final qSnap = await db
        .collection('guild_quests')
        .where('guildId', isEqualTo: widget.guildId)
        .get();
    final quests = qSnap.docs.map((d) => GuildQuestModel.fromDoc(d)).toList();
    final heroGuardianIds = <String, String>{};
    for (final heroId in guild.heroIds) {
      final heroDoc = await db.collection('heroes').doc(heroId).get();
      final guardianId = heroDoc.data()?['guardianId'] as String?;
      if (guardianId != null && guardianId.isNotEmpty) {
        heroGuardianIds[heroId] = guardianId;
      }
    }

    if (mounted) {
      setState(() {
        _guild = guild;
        _quests = quests;
        _heroGuardianIds = heroGuardianIds;
        _isOwner = guild.ownerId == _uid;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _guildSub?.cancel();
    _questSub?.cancel();
    _chatMsgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.isParent
        ? ['EVENTS', 'QUESTS', 'COUNCIL']
        : ['EVENTS', 'PROGRESS', 'CHAT'];

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C17),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.castle, color: Color(0xFFFED65B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _guild?.name.toUpperCase() ?? 'MY GUILD',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_isOwner)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.how_to_reg, color: Colors.white),
                  if ((_guild?.pendingGuardianIds.length ?? 0) +
                          (_guild?.pendingHeroIds.length ?? 0) >
                      0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuildPendingScreen(
                      guildId: widget.guildId,
                      isParent: widget.isParent,
                    ),
                  ),
                );
                _load();
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuildDetailScreen(
                  guildId: widget.guildId,
                  currentMemberId: _uid,
                  isParent: widget.isParent,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1C1C17),
            onSelected: (val) async {
              if (val == 'leave' && _uid != null) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFFFCF9F0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    title: const Text(
                      'LEAVE GUILD',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C1C17),
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to leave this guild?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBA1A1A),
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('LEAVE'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final field = widget.isParent ? 'guardianIds' : 'heroIds';
                  final coll = widget.isParent ? 'guardians' : 'heroes';
                  await FirebaseFirestore.instance
                      .collection('guilds')
                      .doc(widget.guildId)
                      .update({
                        field: FieldValue.arrayRemove([_uid!]),
                      });
                  await FirebaseFirestore.instance
                      .collection(coll)
                      .doc(_uid!)
                      .update({'guildId': ''});
                  if (mounted) {
                    // Gọi callback → GuildEntryScreen reload → chuyển về Lobby
                    widget.onLeave?.call();
                  }
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Color(0xFFBA1A1A), size: 18),
                    SizedBox(width: 10),
                    Text(
                      'LEAVE GUILD',
                      style: TextStyle(
                        color: Color(0xFFBA1A1A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final sel = _tab == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = e.key),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFFFED65B) : Colors.transparent,
                      border: const Border(
                        right: BorderSide(color: Color(0xFF4D4635), width: 1),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sel ? const Color(0xFF1C1C17) : Colors.white60,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: _loading || _guild == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF1C1C17),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _buildTab(),
              ),
            ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case 0:
        return _buildEvents();
      case 1:
        return widget.isParent ? _buildParentQuests() : _buildHeroProgress();
      case 2:
        return _buildChat();
      default:
        return const SizedBox();
    }
  }

  // ── EVENTS ────────────────────────────────────────────────────────────────────
  Widget _buildEvents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ACTIVE EVENTS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C17),
              ),
            ),
            if (_isOwner)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'CREATE EVENT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () => _showCreateEventDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C17),
                  foregroundColor: const Color(0xFFFED65B),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
          ],
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
            if (state == null) return _buildNoEventCard();
            if (state.isCompleted) return _buildEventEndedCard(state);
            return _buildBossActiveCard(state);
          },
        ),
      ],
    );
  }

  Widget _buildNoEventCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Center(
        child: Text(
          _isOwner
              ? 'No events yet. Tap CREATE EVENT to start one.'
              : 'No active events right now.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF77574D),
          ),
        ),
      ),
    );
  }

  Widget _buildBossActiveCard(GuildEventState state) {
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BossRaidScreen(
                      guildId: widget.guildId,
                      currentMemberId: _uid,
                      canAttack: !widget.isParent,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'ENTER RAID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventEndedCard(GuildEventState state) {
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
          // Toàn bộ phần tóm tắt bấm được → mở bảng kết quả.
          InkWell(
            onTap: () => _showResultBoardDialog(state),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 16,
                      color: Color(0xFFFFB74D),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tap to view results',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB74D),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFFFFB74D),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'CREATE NEW EVENT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResultBoardDialog(GuildEventState state) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1C1C17),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF2E7D32), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EVENT RESULTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF66E07A),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '🏆 ${state.bossName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'RANKING (DAMAGE)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(child: _buildResultBoard()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  color: rank == 1
                      ? const Color(0xFFD4AF37)
                      : Colors.white24,
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

  void _showCreateEventDialog() {
    String eventType = 'boss_raid';
    String bossId = BossRaidService.defaultBossId;

    const fieldDecoration = InputDecoration(
      filled: true,
      fillColor: Color(0xFFEBE8DF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF1C1C17)),
      ),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9F0),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            'CREATE EVENT',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: eventType,
                decoration: fieldDecoration,
                dropdownColor: const Color(0xFFFCF9F0),
                items: const [
                  DropdownMenuItem(
                    value: 'boss_raid',
                    child: Text('BOSS RAID'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setS(() => eventType = value);
                },
              ),
              const SizedBox(height: 12),
              // Chọn boss — gồm boss test máu thấp để mô phỏng boss chết nhanh.
              DropdownButtonFormField<String>(
                initialValue: bossId,
                decoration: fieldDecoration,
                dropdownColor: const Color(0xFFFCF9F0),
                items: const [
                  DropdownMenuItem(
                    value: 'procrastination_dragon',
                    child: Text('PROCRASTINATION DRAGON'),
                  ),
                  DropdownMenuItem(
                    value: 'test_dummy_boss',
                    child: Text('TEST DUMMY (LOW HP)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setS(() => bossId = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Color(0xFF7F7663)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C17),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                if (_uid == null) return;
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                try {
                  if (eventType == 'boss_raid') {
                    await BossRaidService().createBossRaidEvent(
                      guildId: widget.guildId,
                      createdBy: _uid!,
                      bossId: bossId,
                    );
                  }
                  _load();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: const Color(0xFFBA1A1A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('CREATE'),
            ),
          ],
        ),
      ),
    );
  }

  // ── PARENT QUESTS ─────────────────────────────────────────────────────────────
  Widget _buildParentQuests() {
    final now = DateTime.now();
    final voting = _quests
        .where((q) => !q.isApproved && !q.isRejected)
        .toList();
    final incomplete = _quests
        .where(
          (q) =>
              q.isApproved &&
              !q.isCompleted &&
              !q.isRejected &&
              !q.deadline.isBefore(now),
        )
        .toList();
    final history = _quests
        .where(
          (q) =>
              q.isRejected ||
              q.isCompleted ||
              (q.isApproved && !q.isCompleted && q.deadline.isBefore(now)),
        )
        .toList();
    final guardianCount = _guild?.guardianIds.length ?? 1;

    List<Widget> questCards(List<GuildQuestModel> quests) => quests
        .map(
          (q) => _QuestCard(
            quest: q,
            guardianCount: guardianCount,
            isParent: true,
            isOwner: _isOwner,
            currentUid: _uid,
            heroGuardianIds: _heroGuardianIds,
            onRefresh: _load,
            onOpenTasks: widget.onOpenTasks,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'GUILD QUESTS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C17),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text(
                'PROPOSE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              onPressed: () => _showProposeDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C17),
                foregroundColor: const Color(0xFFFED65B),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),

        if (incomplete.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'INCOMPLETE QUESTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...questCards(incomplete),
        ],

        if (voting.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'VOTING PENDING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8F7100),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...questCards(voting),
        ],

        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'QUEST HISTORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F7663),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...questCards(history),
        ],

        if (_quests.isEmpty)
          _emptyState('No quests yet.\nPropose one to get started!'),
      ],
    );
  }

  // ── HERO PROGRESS ─────────────────────────────────────────────────────────────
  Widget _buildHeroProgress() {
    final now = DateTime.now();
    final incomplete = _quests
        .where(
          (q) =>
              q.isApproved &&
              !q.isCompleted &&
              !q.isRejected &&
              !q.deadline.isBefore(now),
        )
        .toList();
    final history = _quests
        .where(
          (q) =>
              q.isRejected ||
              q.isCompleted ||
              (q.isApproved && !q.isCompleted && q.deadline.isBefore(now)),
        )
        .toList();

    List<Widget> questCards(List<GuildQuestModel> quests) => quests
        .map(
          (q) => _QuestCard(
            quest: q,
            guardianCount: 1,
            isParent: false,
            isOwner: false,
            currentUid: _uid,
            heroGuardianIds: _heroGuardianIds,
            onRefresh: _load,
            onOpenTasks: widget.onOpenTasks,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GUILD QUEST PROGRESS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C1C17),
          ),
        ),
        const SizedBox(height: 12),
        if (incomplete.isEmpty && history.isEmpty)
          _emptyState('No guild quest history yet.'),
        if (incomplete.isNotEmpty) ...[
          const Text(
            'INCOMPLETE QUESTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF388E3C),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...questCards(incomplete),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'QUEST HISTORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F7663),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...questCards(history),
        ],
      ],
    );
  }

  // ── CHAT ──────────────────────────────────────────────────────────────────────
  Widget _buildChat() {
    final label = widget.isParent ? 'GUARDIAN COUNCIL' : 'FELLOWSHIP CHAT';
    final collectionName = widget.isParent
        ? 'council_messages'
        : 'fellowship_messages';

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C1C17),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE8DF),
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
          ),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('guilds')
                      .doc(widget.guildId)
                      .collection(collectionName)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFFBA1A1A)),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1C1C17),
                        ),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Say hello!',
                          style: TextStyle(
                            color: Color(0xFF7F7663),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();
                        final senderId = data['senderId'] as String? ?? '';
                        final senderName =
                            data['senderName'] as String? ?? 'Anonymous';
                        final content = data['content'] as String? ?? '';
                        final timestamp = data['createdAt'] as Timestamp?;
                        final timeStr = timestamp != null
                            ? "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                            : "";
                        final isSelf = senderId == _uid;

                        return _chat(
                          senderName,
                          content,
                          timeStr,
                          isSelf: isSelf,
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF1C1C17), width: 1),
                  ),
                  color: Color(0xFFFCF9F0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatMsgCtrl,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF1C1C17)),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chat(
    String sender,
    String msg,
    String time, {
    required bool isSelf,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: isSelf
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isSelf && time.isNotEmpty) ...[
              Text(
                time,
                style: const TextStyle(fontSize: 8, color: Color(0xFF7F7663)),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              sender,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7F7663),
              ),
            ),
            if (!isSelf && time.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 8, color: Color(0xFF7F7663)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelf ? const Color(0xFF1C1C17) : const Color(0xFFF6F3EA),
            border: Border.all(color: const Color(0xFF1C1C17)),
          ),
          child: Text(
            msg,
            style: TextStyle(
              color: isSelf ? Colors.white : const Color(0xFF1C1C17),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Text(
        msg,
        style: const TextStyle(
          color: Color(0xFF7F7663),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );

  void _showProposeDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    int days = 7;
    String attribute = 'STRENGTH';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9F0),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            'PROPOSE QUEST',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(titleCtrl, 'Quest title'),
                const SizedBox(height: 10),
                _dialogField(descCtrl, 'Description'),
                const SizedBox(height: 10),
                _dialogField(
                  amountCtrl,
                  'Target amount (number)',
                  isNumber: true,
                ),
                const SizedBox(height: 10),
                _dialogField(unitCtrl, 'Unit (e.g. pages, push-ups)'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: attribute,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFEBE8DF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: Color(0xFF1C1C17)),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  dropdownColor: const Color(0xFFFCF9F0),
                  items: const [
                    DropdownMenuItem(
                      value: 'STRENGTH',
                      child: Text('STRENGTH'),
                    ),
                    DropdownMenuItem(
                      value: 'INTELLECT',
                      child: Text('INTELLECT'),
                    ),
                    DropdownMenuItem(value: 'SPIRIT', child: Text('SPIRIT')),
                    DropdownMenuItem(value: 'AGILITY', child: Text('AGILITY')),
                  ],
                  onChanged: (value) {
                    if (value != null) setS(() => attribute = value);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Duration (days):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => setS(() {
                            if (days > 1) days--;
                          }),
                        ),
                        Text(
                          '$days',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setS(() => days++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Color(0xFF7F7663)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C17),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || _uid == null) return;
                Navigator.pop(ctx);
                await GuildService().proposeQuest(
                  guildId: widget.guildId,
                  createdBy: _uid!,
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  attribute: attribute,
                  targetAmount: int.tryParse(amountCtrl.text.trim()) ?? 100,
                  unit: unitCtrl.text.trim(),
                  daysAvailable: days,
                  heroIds: _guild?.heroIds ?? [],
                );
                _load();
              },
              child: const Text('PROPOSE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) => TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    inputFormatters:
        isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
    style: const TextStyle(fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7F7663)),
      filled: true,
      fillColor: const Color(0xFFEBE8DF),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Color(0xFF1C1C17)),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

// ── Quest Card ────────────────────────────────────────────────────────────────
class _QuestCard extends StatefulWidget {
  final GuildQuestModel quest;
  final int guardianCount;
  final bool isParent;
  final bool isOwner;
  final String? currentUid;
  final Map<String, String> heroGuardianIds;
  final VoidCallback onRefresh;
  final VoidCallback? onOpenTasks;

  const _QuestCard({
    required this.quest,
    required this.guardianCount,
    required this.isParent,
    required this.isOwner,
    required this.currentUid,
    required this.heroGuardianIds,
    required this.onRefresh,
    this.onOpenTasks,
  });

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  bool _voting = false;

  int get _totalProgress =>
      widget.quest.heroProgress.values.fold(0, (a, b) => a + b);
  int get _totalTarget => widget.quest.assignedHeroIds.isEmpty
      ? widget.quest.targetAmount
      : (widget.quest.requiredPerHero * widget.quest.assignedHeroIds.length);
  double get _percent =>
      _totalTarget > 0 ? (_totalProgress / _totalTarget).clamp(0.0, 1.0) : 0;
  int get _votePercent => widget.guardianCount > 0
      ? ((widget.quest.upvotes.length / widget.guardianCount) * 100).round()
      : 0;
  bool get _myProgress =>
      widget.quest.heroProgress.containsKey(widget.currentUid) &&
      (widget.quest.heroProgress[widget.currentUid] ?? 0) >=
          widget.quest.requiredPerHero;
  bool get _isExpired =>
      widget.quest.isApproved &&
      !widget.quest.isCompleted &&
      !widget.quest.isRejected &&
      widget.quest.deadline.isBefore(DateTime.now());
  bool get _isLocked =>
      widget.quest.isRejected || widget.quest.isCompleted || _isExpired;

  Future<void> _vote(bool approve) async {
    if (widget.currentUid == null || _voting) return;
    setState(() => _voting = true);
    try {
      await GuildService().voteQuest(
        guildId: widget.quest.guildId,
        questId: widget.quest.id,
        guardianId: widget.currentUid!,
        approve: approve,
      );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _ownerApprove() async {
    if (widget.currentUid == null || _voting) return;
    setState(() => _voting = true);
    try {
      await GuildService().ownerApproveQuest(
        guildId: widget.quest.guildId,
        questId: widget.quest.id,
        ownerId: widget.currentUid!,
      );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _ownerReject() async {
    if (widget.currentUid == null || _voting) return;
    setState(() => _voting = true);
    try {
      await GuildService().ownerRejectQuest(
        guildId: widget.quest.guildId,
        questId: widget.quest.id,
        ownerId: widget.currentUid!,
      );
      widget.onRefresh();
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double percent, Color color) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
          Center(
            child: Text(
              '${(percent * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(GuildQuestModel q) {
    late final String label;
    late final Color background;
    late final Color foreground;

    if (q.isRejected) {
      label = 'REMOVED';
      background = const Color(0xFFBA1A1A);
      foreground = Colors.white;
    } else if (q.isCompleted) {
      label = 'COMPLETED';
      background = const Color(0xFF1B6D24);
      foreground = Colors.white;
    } else if (_isExpired) {
      label = 'EXPIRED';
      background = const Color(0xFF8F7100);
      foreground = Colors.white;
    } else if (_myProgress && !widget.isParent) {
      label = 'DONE';
      background = const Color(0xFF388E3C);
      foreground = Colors.white;
    } else if (q.isApproved) {
      label = 'ACTIVE';
      background = const Color(0xFF388E3C);
      foreground = Colors.white;
    } else {
      label = 'VOTING';
      background = const Color(0xFFFED65B);
      foreground = const Color(0xFF1C1C17);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: foreground,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quest;
    final daysLeft = q.deadline.difference(DateTime.now()).inDays;
    final hasVoted =
        q.upvotes.contains(widget.currentUid) ||
        q.downvotes.contains(widget.currentUid);
    final myVoteLabel = q.upvotes.contains(widget.currentUid)
        ? 'YOU APPROVED ✓'
        : q.downvotes.contains(widget.currentUid)
        ? 'YOU REJECTED ✗'
        : 'NOT VOTED YET';
    final removedBy = q.rejectionReason == 'admin'
        ? 'REMOVED BY LEADER'
        : 'REMOVED BY VOTE';

    // Status theme colors
    Color statusColor;
    if (q.isRejected) {
      statusColor = const Color(0xFFBA1A1A);
    } else if (q.isCompleted) {
      statusColor = const Color(0xFF1B6D24);
    } else if (_isExpired) {
      statusColor = const Color(0xFF8F7100);
    } else if (q.isApproved) {
      statusColor = const Color(0xFF388E3C);
    } else {
      statusColor = const Color(0xFFFED65B);
    }

    final bool isDoneBg = _myProgress && !widget.isParent;
    final Color cardBg = isDoneBg
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF6F3EA);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: isDoneBg
            ? [
                BoxShadow(
                  color: const Color(0xFF388E3C).withOpacity(0.15),
                  blurRadius: 0,
                  offset: const Offset(3, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF1C1C17).withOpacity(0.08),
                  blurRadius: 0,
                  offset: const Offset(3, 3),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Left Accent Color Block representing Quest status
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: statusColor),
          ),
          // Vertical Separator Border
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            width: 1.5,
            child: Container(color: const Color(0xFF1C1C17)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7.5),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Header Row: Title & Status Chip
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            q.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1C17),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(q),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Description text
                    Text(
                      q.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4D4635),
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Badges Wrap (Reward, Deadline, Targets)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge(
                          icon: Icons.star,
                          text: '${q.expReward} EXP',
                          color: const Color(0xFF735C00),
                          bgColor: const Color(0xFFFED65B).withOpacity(0.15),
                        ),
                        _buildBadge(
                          icon: Icons.hourglass_top,
                          text: daysLeft >= 0
                              ? '$daysLeft DAYS LEFT'
                              : 'EXPIRED',
                          color: daysLeft >= 0
                              ? const Color(0xFF1C1C17)
                              : const Color(0xFFBA1A1A),
                          bgColor: daysLeft >= 0
                              ? Colors.transparent
                              : const Color(0xFFBA1A1A).withOpacity(0.08),
                        ),
                        _buildBadge(
                          icon: Icons.flag,
                          text:
                              'GOAL: ${q.targetAmount} ${q.unit.toUpperCase()}',
                          color: const Color(0xFF1C1C17),
                          bgColor: Colors.transparent,
                        ),
                      ],
                    ),
                    if (q.isRejected) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Reason: $removedBy'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ] else if (_isExpired) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'DEADLINE PASSED BEFORE COMPLETION',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8F7100),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],

                    // Divider Line
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1.5,
                        color: const Color(0xFF1C1C17).withOpacity(0.15),
                      ),
                    ),

                    // Voting Flow UI (Guardians & not approved yet)
                    if (!q.isApproved && !q.isRejected && widget.isParent) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GUARDIAN CONSENSUS: $_votePercent% / 70% NEEDED',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1C17),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${q.upvotes.length} ✓ · ${q.downvotes.length} ✗',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7F7663),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _bar(
                        _votePercent / 100,
                        _votePercent >= 70
                            ? const Color(0xFF388E3C)
                            : const Color(0xFFBA1A1A),
                      ),
                      const SizedBox(height: 12),
                      if (widget.isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.gavel, size: 14),
                                label: const Text('LEADER APPROVE'),
                                onPressed: _voting ? null : _ownerApprove,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C1C17),
                                  foregroundColor: const Color(0xFFFED65B),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFF1C1C17),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.close, size: 14),
                                label: const Text('LEADER REJECT'),
                                onPressed: _voting ? null : _ownerReject,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBA1A1A),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFF1C1C17),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!hasVoted)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.thumb_up, size: 14),
                                label: const Text('APPROVE'),
                                onPressed: _voting ? null : () => _vote(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF388E3C),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFF1C1C17),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.thumb_down, size: 14),
                                label: const Text('REJECT'),
                                onPressed: _voting ? null : () => _vote(false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBA1A1A),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  elevation: 0,
                                  side: const BorderSide(
                                    color: Color(0xFF1C1C17),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBE8DF),
                              border: Border.all(
                                color: const Color(0xFF1C1C17),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              myVoteLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1C1C17),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],

                    // Progress Tracking UI (Approved Quests)
                    if (q.isApproved && !q.isRejected) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GUILD PROGRESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1C17),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '$_totalProgress / $_totalTarget ${q.unit.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1C17),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _bar(_percent, const Color(0xFFFED65B)),
                      const SizedBox(height: 6),
                      Text(
                        '${(_percent * 100).toInt()}% COMPLETED  ·  ${q.heroCompletionApproved.values.where((v) => v).length}/${q.assignedHeroIds.length} HEROES CERTIFIED',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7F7663),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      // Hero's Own Contribution Section
                      if (!_isLocked &&
                          !widget.isParent &&
                          q.assignedHeroIds.contains(widget.currentUid)) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C17),
                            border: Border.all(
                              color: const Color(0xFFFED65B),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'YOUR CONTRIBUTION',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${widget.quest.heroProgress[widget.currentUid] ?? 0} / ${q.requiredPerHero} ${q.unit.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFED65B),
                                    ),
                                  ),
                                ],
                              ),
                              if (!_myProgress) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.bolt, size: 14),
                                    label: const Text('GO TO QUEST TASK'),
                                    onPressed: widget.onOpenTasks,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFED65B),
                                      foregroundColor: const Color(0xFF1C1C17),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Parent Side: Approve Hero Completions List
                      if (!_isExpired &&
                          !q.isCompleted &&
                          widget.isParent &&
                          q.assignedHeroIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'HERO SUBMISSIONS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7F7663),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...q.assignedHeroIds.map((hid) {
                          final heroProgress = q.heroProgress[hid] ?? 0;
                          final approved =
                              q.heroCompletionApproved[hid] == true;
                          final done = heroProgress >= q.requiredPerHero;
                          final canApprove =
                              widget.currentUid != null &&
                              widget.heroGuardianIds[hid] == widget.currentUid;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBE8DF),
                              border: Border.all(
                                color: const Color(0xFF1C1C17),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hid.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1C1C17),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'PROGRESS: $heroProgress / ${q.requiredPerHero} ${q.unit.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF4D4635),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (approved)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      border: Border.all(
                                        color: const Color(0xFF388E3C),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'APPROVED ✓',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF388E3C),
                                      ),
                                    ),
                                  )
                                else if (done && canApprove)
                                  ElevatedButton(
                                    onPressed: () async {
                                      await GuildService()
                                          .approveHeroCompletion(
                                            questId: q.id,
                                            heroId: hid,
                                            guardianId: widget.currentUid,
                                          );
                                      widget.onRefresh();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF388E3C),
                                      foregroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: Color(0xFF1C1C17),
                                        width: 1,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    child: const Text(
                                      'APPROVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  )
                                else if (done)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9C4),
                                      border: Border.all(
                                        color: const Color(0xFFF57F17),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'WAITING VERIFICATION',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFF57F17),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECEFF1),
                                      border: Border.all(
                                        color: const Color(0xFF546E7A),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'IN PROGRESS',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF546E7A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
