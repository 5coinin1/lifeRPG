import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guild_detail_screen.dart';
import 'create_guild_screen.dart';

/// Màn hình khi user chưa tham gia guild nào.
/// - Parent: có nút "CREATE GUILD" + search + danh sách gợi ý
/// - Hero:   chỉ search + danh sách gợi ý
class GuildLobbyScreen extends StatefulWidget {
  final bool isParent;
  final String? firestoreId; // doc ID trong guardians/heroes
  final VoidCallback? onJoinedOrCreated; // callback để Entry reload
  const GuildLobbyScreen({
    super.key,
    required this.isParent,
    this.firestoreId,
    this.onJoinedOrCreated,
  });

  @override
  State<GuildLobbyScreen> createState() => _GuildLobbyScreenState();
}

class _GuildLobbyScreenState extends State<GuildLobbyScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _guilds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGuilds();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGuilds() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('guilds').get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'name': d['name'] ?? '',
          'description': d['description'] ?? '',
          'tag': d['tag'] ?? '',
          'iconName': d['iconName'] ?? 'shield',
          'level': d['level'] ?? 1,
          'members':
              (List.from(d['guardianIds'] ?? []).length +
              List.from(d['heroIds'] ?? []).length),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _guilds = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _guilds;
    return _guilds
        .where(
          (g) =>
              g['name'].toString().toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C17),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'GUILD HALL',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFED65B),
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadGuilds,
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFFED65B), width: 2),
        ),
      ),
      body: Column(
        children: [
          // ── Banner chưa có guild ──────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF1C1C17),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOU HAVE NO GUILD.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8F7100),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join a guild to unlock\ncollective power & rewards.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                // Parent: nút tạo guild
                if (widget.isParent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'CREATE YOUR OWN GUILD',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final guardianId = widget.firestoreId;
                        if (guardianId == null || guardianId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot find your guardian profile. Please sign in again.',
                              ),
                              backgroundColor: Color(0xFFBA1A1A),
                            ),
                          );
                          return;
                        }

                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateGuildScreen(guardianId: guardianId),
                          ),
                        );
                        if (result == true) {
                          // Guild tạo thành công → báo Entry Screen reload → vào Dashboard
                          widget.onJoinedOrCreated?.call();
                        } else {
                          _loadGuilds();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFED65B),
                        foregroundColor: const Color(0xFF1C1C17),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (!widget.isParent)
                  const Text(
                    'Heroes must be invited or request to join a guild.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8F7100)),
                  ),
              ],
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEBE8DF),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1C1C17), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF4D4635)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C17),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'SEARCH GUILDS...',
                      hintStyle: TextStyle(
                        color: Color(0xFF7F7663),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF4D4635),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),

          // ── Guild list ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
                  )
                : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _loadGuilds,
                    color: const Color(0xFF1C1C17),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'RECOMMENDED GUILDS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7F7663),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        ..._filtered.map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _GuildCard(
                              guild: g,
                              isParent: widget.isParent,
                              currentMemberId: widget.firestoreId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.castle_outlined, size: 64, color: Color(0xFF7F7663)),
          SizedBox(height: 16),
          Text(
            'NO GUILDS FOUND',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F7663),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guild Card Widget ────────────────────────────────────────────────────────
class _GuildCard extends StatelessWidget {
  final Map<String, dynamic> guild;
  final bool isParent;
  final String? currentMemberId;

  const _GuildCard({
    required this.guild,
    required this.isParent,
    this.currentMemberId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuildDetailScreen(
            guildId: guild['id'],
            currentMemberId: currentMemberId,
            isParent: isParent,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3EA),
          border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C17),
                border: Border.all(color: const Color(0xFF8F7100), width: 2),
              ),
              child: Icon(
                _iconFor(guild['iconName']),
                color: const Color(0xFFFED65B),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          guild['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1C17),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: const Color(0xFF1C1C17),
                        child: Text(
                          'LVL ${guild['level']}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFED65B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: const Color(0xFFEBE8DF),
                    child: Text(
                      guild['tag'],
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF735C00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    guild['description'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4D4635),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${guild['members']} members',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F7663),
                        ),
                      ),
                      const Text(
                        'VIEW DETAILS →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF735C00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'book':
        return Icons.menu_book;
      case 'local_florist':
        return Icons.local_florist;
      default:
        return Icons.shield;
    }
  }
}
