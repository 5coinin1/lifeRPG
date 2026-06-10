import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hero_model.dart';
import '../models/guardian_model.dart';
import '../services/guild_service.dart';

/// Màn hình quản lý yêu cầu tham gia guild — chỉ Guild Master truy cập.
class GuildPendingScreen extends StatefulWidget {
  final String guildId;
  final bool isParent;
  const GuildPendingScreen({
    super.key,
    required this.guildId,
    required this.isParent,
  });

  @override
  State<GuildPendingScreen> createState() => _GuildPendingScreenState();
}

class _GuildPendingScreenState extends State<GuildPendingScreen> {
  List<HeroModel> _pendingHeroes = [];
  List<GuardianModel> _pendingGuardians = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = FirebaseFirestore.instance;
    final doc = await db.collection('guilds').doc(widget.guildId).get();
    if (!doc.exists || !mounted) return;
    final data = doc.data()!;
    final pGuardians = List<String>.from(data['pendingGuardianIds'] ?? []);
    final pHeroes = List<String>.from(data['pendingHeroIds'] ?? []);

    List<HeroModel> heroes = [];
    List<GuardianModel> guardians = [];

    if (pHeroes.isNotEmpty) {
      final s = await db
          .collection('heroes')
          .where(FieldPath.documentId, whereIn: pHeroes)
          .get();
      heroes = s.docs.map((d) => HeroModel.fromDoc(d)).toList();
    }
    if (pGuardians.isNotEmpty) {
      final s = await db
          .collection('guardians')
          .where(FieldPath.documentId, whereIn: pGuardians)
          .get();
      guardians = s.docs.map((d) => GuardianModel.fromDoc(d)).toList();
    }

    if (mounted) {
      setState(() {
        _pendingHeroes = heroes;
        _pendingGuardians = guardians;
        _loading = false;
      });
    }
  }

  Future<void> _approveGuardian(String guardianId) async {
    // Guardian join → allow owner to pick which heroes to bring
    final guardian = _pendingGuardians.firstWhere((g) => g.uid == guardianId);
    if (guardian.heroIds.isEmpty) {
      await GuildService().approveGuardian(
        guildId: widget.guildId,
        guardianId: guardianId,
        selectedHeroIds: [],
      );
      _load();
      return;
    }

    // Dialog chọn hero
    final selected = <String>{};
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9F0),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text(
            'Select heroes to bring\nfrom ${guardian.displayName}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF1C1C17),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: guardian.heroIds
                .map(
                  (hid) => CheckboxListTile(
                    value: selected.contains(hid),
                    onChanged: (v) => ss(() {
                      v! ? selected.add(hid) : selected.remove(hid);
                    }),
                    title: Text(
                      hid,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    activeColor: const Color(0xFF1C1C17),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
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
                Navigator.pop(ctx);
                await GuildService().approveGuardian(
                  guildId: widget.guildId,
                  guardianId: guardianId,
                  selectedHeroIds: selected.toList(),
                );
                _load();
              },
              child: const Text('APPROVE'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveHero(String heroId) async {
    await GuildService().approveHero(guildId: widget.guildId, heroId: heroId);
    _load();
  }

  Future<void> _reject(String id, bool isGuardian) async {
    await GuildService().rejectRequest(
      guildId: widget.guildId,
      memberId: id,
      isGuardian: isGuardian,
    );
    _load();
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
        title: const Text(
          'PENDING REQUESTS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFED65B),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF1C1C17),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pendingGuardians.isEmpty && _pendingHeroes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(
                        child: Text(
                          'No pending requests 🎉',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7F7663),
                          ),
                        ),
                      ),
                    ),
                  if (_pendingGuardians.isNotEmpty) ...[
                    const _SectionHeader('GUARDIAN REQUESTS'),
                    ..._pendingGuardians.map(
                      (g) => _requestTile(
                        name: g.displayName,
                        sub: 'GUARDIAN  ·  ${g.heroIds.length} heroes managed',
                        onApprove: () => _approveGuardian(g.uid),
                        onReject: () => _reject(g.uid, true),
                      ),
                    ),
                  ],
                  if (_pendingHeroes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionHeader('HERO REQUESTS'),
                    ..._pendingHeroes.map(
                      (h) => _requestTile(
                        name: h.displayName,
                        sub:
                            '${h.characterPath}  ·  LVL ${h.level}  ·  ${h.title}',
                        onApprove: () => _approveHero(h.uid),
                        onReject: () => _reject(h.uid, false),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _requestTile({
    required String name,
    required String sub,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1C17),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF7F7663),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF388E3C),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text(
              '✓',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onReject,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: const Text(
              '✗',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7F7663),
        letterSpacing: 1.5,
      ),
    ),
  );
}
