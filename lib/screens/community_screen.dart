import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guild_detail_screen.dart';
import 'guild_entry_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredGuilds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGuilds('');
  }

  Future<void> _loadGuilds(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('guilds')
          .get();
      List<Map<String, dynamic>> guilds = snapshot.docs.map((doc) {
        final data = doc.data();
        int totalMembers =
            List.from(data['heroIds'] ?? []).length +
            List.from(data['guardianIds'] ?? []).length;
        return {
          'id': doc.id,
          'title': data['name'] ?? '',
          'tag': data['tag'] ?? '',
          'description': data['description'] ?? '',
          'members': totalMembers.toString(),
          'icon_name': data['iconName'] ?? 'shield',
        };
      }).toList();

      if (query.isNotEmpty) {
        guilds = guilds
            .where(
              (g) => g['title'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }

      if (mounted) {
        setState(() {
          _filteredGuilds = guilds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredGuilds = _filteredGuilds;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0), // surface
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GuildEntryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C17),
                  foregroundColor: const Color(0xFFFED65B),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "MY GUILD",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildBentoSection(context),
            const SizedBox(height: 32),
            _buildRecommendedHeader(),
            const SizedBox(height: 16),

            // Hiển thị danh sách đã lọc
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
                ),
              )
            else if (filteredGuilds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'NO GUILDS FOUND',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F7663),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredGuilds.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final guild = filteredGuilds[index];
                  return _buildGuildItem(
                    guildId: guild['id'] ?? '',
                    title: guild['title'] ?? '',
                    tag: guild['tag'] ?? '',
                    tagColor: _getTagColor(guild['tag']),
                    description: guild['description'] ?? '',
                    members: guild['members'] ?? '',
                    icon: _getIconData(guild['icon_name']),
                  );
                },
              ),

            const SizedBox(height: 32),
            _buildStatsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _getTagColor(String? tag) {
    switch (tag) {
      case 'Active Now':
        return const Color(0xFF74C570);
      case 'Scholarly':
        return const Color(0xFFFFDAD6);
      case 'Casual':
        return const Color(0xFFFED65B);
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'shield':
        return Icons.shield;
      case 'book':
        return Icons.book;
      case 'flower':
        return Icons.local_florist;
      case 'visibility':
        return Icons.visibility;
      case 'cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'pets':
        return Icons.pets;
      case 'gavel':
        return Icons.gavel;
      default:
        return Icons.help;
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFCF9F0),
      elevation: 0,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            child: const Icon(Icons.person, color: Color(0xFF1C1C17)),
          ),
          const SizedBox(width: 12),
          const Text(
            'THE_ARCHIVE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF1C1C17)),
          onPressed: () {},
        ),
      ],
      shape: const Border(
        bottom: BorderSide(color: Color(0xFF1C1C17), width: 2),
      ),
    );
  }

  Widget _buildSearchBar() {
    final filteredGuilds = _filteredGuilds;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBE8DF),
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
          ),
          child: TextFormField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadGuilds(value);
            },
            decoration: const InputDecoration(
              hintText: "Find a Guild",
              hintStyle: TextStyle(color: Color(0xFF7F7663)),
              prefixIcon: Icon(Icons.search, color: Color(0xFF7F7663)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Danh sách gợi ý hiện ra ngay dưới thanh tìm kiếm khi đang gõ
        if (_searchQuery.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF9F0),
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            child: filteredGuilds.isEmpty
                ? const ListTile(
                    title: Text(
                      'NO GUILDS FOUND',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F7663),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredGuilds.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFF1C1C17)),
                    itemBuilder: (context, index) {
                      final guild = filteredGuilds[index];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF1C1C17),
                              width: 1,
                            ),
                            color: const Color(0xFFE5E2DA),
                          ),
                          child: Icon(
                            _getIconData(guild['icon_name']),
                            size: 18,
                            color: const Color(0xFF1C1C17),
                          ),
                        ),
                        title: Text(
                          guild['title'].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Color(0xFF1C1C17),
                          ),
                        ),
                        subtitle: Text(
                          "${guild['members']} members",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7F7663),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF1C1C17),
                        ),
                        onTap: () {
                          // Xử lý khi bấm vào (ví dụ: điền vào ô tìm kiếm hoặc vào thẳng trang Guild)
                          setState(() {
                            _searchQuery = guild['title'];
                          });
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildBentoSection(BuildContext context) {
    return Column(
      children: [
        _buildCreateGuildCard(),
        const SizedBox(height: 16),
        _buildPerksCard(),
      ],
    );
  }

  Widget _buildCreateGuildCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFED65B), // Yellow
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CREATE YOUR OWN GUILD",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Assemble your fellowship. Define your creed. Master the archives together.",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF1C1C17),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF735C00),
                child: const Text(
                  "NEW FEATURE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFED65B),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GuildEntryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF574500),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF1C1C17), width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "BEGIN FOUNDING",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFED65B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
      ),
      child: Column(
        children: const [
          Icon(Icons.stars, size: 40, color: Color(0xFF77574D)),
          SizedBox(height: 8),
          Text(
            "GUILD PERKS",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
            ),
          ),
          SizedBox(height: 4),
          Text(
            "XP Boosts & Exclusive Loot Vaults",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7F7663),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RECOMMENDED",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C17),
              ),
            ),
            const Text(
              "GUILDS",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1C1C17),
              ),
            ),
            const SizedBox(height: 4),
            Container(height: 3, width: 120, color: const Color(0xFF735C00)),
          ],
        ),
        const Text(
          "VIEW ALL\nARCHIVES",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF77574D),
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildGuildItem({
    required String guildId,
    required String title,
    required String tag,
    required Color tagColor,
    required String description,
    required String members,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
              color: const Color(0xFFE5E2DA),
            ),
            child: Icon(icon, size: 30, color: const Color(0xFF1C1C17)),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C17),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: tagColor,
            child: Text(
              tag.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C17),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4D4635),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MEMBERS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F7663),
                    ),
                  ),
                  Text(
                    members,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C17),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuildDetailScreen(guildId: guildId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF77574D),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF1C1C17), width: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "JOIN",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildStatItem("TOTAL GUILDS", "1,402", const Color(0xFF1C1C17)),
        _buildStatItem("ACTIVE QUESTS", "24.5k", const Color(0xFF1B6D24)),
        _buildStatItem("GOLD CIRCULATED", "8.9M", const Color(0xFF735C00)),
        _buildStatItem("WORLD BOSSES DOWN", "12", const Color(0xFFBA1A1A)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE8DF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7F7663),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
