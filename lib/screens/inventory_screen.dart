import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/hero_model.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  final String heroUid;
  final int initialTabIndex;

  const InventoryScreen({
    super.key,
    required this.heroUid,
    this.initialTabIndex = 0,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _starterChecked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _ensureStarter(HeroModel hero) async {
    if (_starterChecked) return;
    _starterChecked = true;
    await InventoryService.ensureStarterInventory(hero);
  }

  Widget _buildRarityTag(String rarity) {
    Color bgColor;
    Color textColor;

    switch (rarity) {
      case 'UNCOMMON':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'RARE':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'LEGENDARY':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        break;
      case 'MYTHIC':
        bgColor = const Color(0xFFFCE4EC);
        textColor = const Color(0xFFC2185B);
        break;
      default:
        bgColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF616161);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor, width: 1),
      ),
      child: Text(
        rarity,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSourceTag(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: const Color(0xFF1C1C17),
      child: Text(
        source.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFED65B),
        ),
      ),
    );
  }

  Widget _buildEmptySlot(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3EA),
          border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        ),
        child: Text(
          'NO OWNED $label YET',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7F7663),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentList(
    List<InventoryEntry> entries,
    HeroModel hero,
    String slotType,
  ) {
    final items = entries.where((e) => e.equipment.type == slotType).toList();
    String? currentEquippedId;
    if (slotType == 'WEAPON') currentEquippedId = hero.equippedWeaponId;
    if (slotType == 'ARMOR') currentEquippedId = hero.equippedArmorId;
    if (slotType == 'PET') currentEquippedId = hero.equippedPetId;

    if (items.isEmpty) return _buildEmptySlot(slotType);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = items[index];
        final item = entry.equipment;
        final owned = entry.inventoryItem;
        final isEquipped = item.id == currentEquippedId;
        final isLocked = hero.level < item.requiredLevel || owned.locked;

        return Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? const Color(0xFFF6F3EA) : Colors.white,
              border: Border.all(
                color: const Color(0xFF1C1C17),
                width: isEquipped ? 3 : 2,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: slotType == 'ARMOR'
                        ? const Color(0xFF1C1C17)
                        : const Color(0xFFFCF9F0),
                    border: Border.all(
                      color: const Color(0xFF1C1C17),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, err, stack) =>
                        const Icon(Icons.image),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1C1C17),
                              ),
                            ),
                          ),
                          _buildRarityTag(item.rarity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildSourceTag(owned.source),
                          if (owned.quantity > 1)
                            _buildSourceTag('x${owned.quantity}'),
                          if (owned.tradable) _buildSourceTag('tradable'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4D4635),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ...item.statModifiers.entries.map((entry) {
                            final isPositive = entry.value >= 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                border: Border.all(
                                  color: isPositive
                                      ? const Color(0xFF81C784)
                                      : const Color(0xFFE57373),
                                ),
                              ),
                              child: Text(
                                "${isPositive ? '+' : ''}${entry.value} ${entry.key}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            );
                          }),
                          if (item.hpBonus > 0)
                            Text(
                              '+${item.hpBonus} HP',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFC62828),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isLocked)
                      Text(
                        'LVL ${item.requiredLevel}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFBA1A1A),
                        ),
                      )
                    else if (isEquipped) ...[
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        color: const Color(0xFF1C1C17),
                        alignment: Alignment.center,
                        child: Text(
                          'EQUIPPED',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () async {
                            await InventoryService.unequipItem(
                              heroId: widget.heroUid,
                              entry: entry,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Unequipped ${item.name}.'),
                                backgroundColor: const Color(0xFF7F7663),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEBEE),
                            foregroundColor: const Color(0xFFBA1A1A),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            side: const BorderSide(
                              color: Color(0xFFBA1A1A),
                              width: 1.5,
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'UNEQUIP',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            await InventoryService.equipItem(
                              heroId: widget.heroUid,
                              entry: entry,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Equipped ${item.name}!'),
                                backgroundColor: const Color(0xFF1C1C17),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C17),
                            foregroundColor: const Color(0xFFFCF9F0),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'EQUIP',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HeroModel?>(
      stream: AuthService.getHeroStream(widget.heroUid),
      builder: (context, heroSnapshot) {
        final hero = heroSnapshot.data;
        if (hero == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFFCF9F0),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            ),
          );
        }

        _ensureStarter(hero);

        return StreamBuilder<List<InventoryEntry>>(
          stream: InventoryService.inventoryEntriesStream(widget.heroUid),
          builder: (context, inventorySnapshot) {
            final entries = inventorySnapshot.data ?? [];
            return Scaffold(
              backgroundColor: const Color(0xFFFCF9F0),
              appBar: AppBar(
                backgroundColor: const Color(0xFFFCF9F0),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C17)),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'THE ARMORY',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1C17),
                    letterSpacing: 1.0,
                  ),
                ),
                shape: const Border(
                  bottom: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1C1C17),
                  unselectedLabelColor: const Color(0xFF7F7663),
                  indicatorColor: const Color(0xFF1C1C17),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                  tabs: const [
                    Tab(text: 'WEAPONS'),
                    Tab(text: 'ARMORS'),
                    Tab(text: 'PETS'),
                  ],
                ),
              ),
              body: inventorySnapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1C1C17),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEquipmentList(entries, hero, 'WEAPON'),
                        _buildEquipmentList(entries, hero, 'ARMOR'),
                        _buildEquipmentList(entries, hero, 'PET'),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
