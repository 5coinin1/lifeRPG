import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment_model.dart';
import '../models/hero_model.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

/// Xem (read-only) loadout đang trang bị của 1 hero — dùng cho phụ huynh.
/// Hiển thị 3 ô: Armor (trái) | Weapon (trên-phải) + Pet (dưới-phải).
class HeroGearViewScreen extends StatelessWidget {
  final String heroUid;
  final String? heroName;

  const HeroGearViewScreen({super.key, required this.heroUid, this.heroName});

  EquipmentModel? _equipped(List<InventoryEntry> inv, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final e in inv) {
      if (e.equipment.id == id) return e.equipment;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
          heroName != null ? "${heroName!}'S GEAR".toUpperCase() : 'EQUIPPED GEAR',
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
      ),
      body: StreamBuilder<HeroModel?>(
        stream: AuthService.getHeroStream(heroUid),
        builder: (context, heroSnap) {
          final hero = heroSnap.data;
          if (hero == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            );
          }
          return StreamBuilder<List<InventoryEntry>>(
            stream: InventoryService.inventoryEntriesStream(heroUid),
            builder: (context, invSnap) {
              final inv = invSnap.data ?? [];
              final armor = _equipped(inv, hero.equippedArmorId);
              final weapon = _equipped(inv, hero.equippedWeaponId);
              final pet = _equipped(inv, hero.equippedPetId);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CURRENTLY EQUIPPED',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: const Color(0xFF77574D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3EA),
                        border: Border.all(
                          color: const Color(0xFF1C1C17),
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1C1C17),
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        height: 280,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _slot(
                                'ARMOR',
                                const Color(0xFF455A64),
                                Icons.shield_outlined,
                                armor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _slot(
                                      'WEAPON',
                                      const Color(0xFFBA1A1A),
                                      Icons.gavel_outlined,
                                      weapon,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _slot(
                                      'PET',
                                      const Color(0xFFD4AF37),
                                      Icons.pets_outlined,
                                      pet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _slot(
    String label,
    Color labelColor,
    IconData emptyIcon,
    EquipmentModel? item,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C17),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Column(
        children: [
          Container(
            height: 22,
            width: double.infinity,
            color: labelColor,
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: item == null
                  ? Center(
                      child: Icon(emptyIcon, size: 36, color: Colors.white24),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          Icon(emptyIcon, size: 36, color: Colors.white24),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              item?.name ?? 'NONE',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item == null ? Colors.white38 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
