import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/hero_model.dart';
import '../models/equipment_model.dart';
import '../services/inventory_service.dart';
import 'inventory_screen.dart';

// --- MODELS ---
// --- MODELS DELETED ---

class HeroScreen extends StatefulWidget {
  const HeroScreen({super.key});

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> {
  final TextEditingController _inviteCodeController = TextEditingController();
  bool _isLinking = false;
  // --- BASE STATS ---
  // Giờ sẽ lấy từ HeroModel thay vì hardcode
  bool _starterChecked = false;

  final EquipmentModel _defaultWeapon = EquipmentModel(
    id: '',
    name: 'BARE HANDS',
    type: 'WEAPON',
    rarity: 'COMMON',
    tier: 0,
    requiredLevel: 1,
    statModifiers: {},
    hpBonus: 0,
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png',
    description: 'Just your fists.',
  );
  final EquipmentModel _defaultArmor = EquipmentModel(
    id: '',
    name: 'CLOTH TUNIC',
    type: 'ARMOR',
    rarity: 'COMMON',
    tier: 0,
    requiredLevel: 1,
    statModifiers: {},
    hpBonus: 0,
    imageUrl:
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/707.png',
    description: 'Basic tunic.',
  );
  final EquipmentModel _defaultPet = EquipmentModel(
    id: '',
    name: 'NO COMPANION',
    type: 'PET',
    rarity: 'COMMON',
    tier: 0,
    requiredLevel: 1,
    statModifiers: {},
    hpBonus: 0,
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png',
    description: 'No pet.',
  );

  // --- GOLD & LEVEL ---
  // Sẽ lấy trực tiếp từ HeroModel
  // --- ITEM LISTS ---
  // Danh sách cứng đã bị xóa

  String? _heroUid;

  @override
  void initState() {
    super.initState();
    _loadHero();
  }

  void _loadHero() async {
    final acc = await AuthService.getCurrentAccount();
    if (acc != null && mounted) {
      setState(() {
        _heroUid = acc.uid;
      });
    }
  }

  Future<void> _ensureStarterInventory(HeroModel hero) async {
    if (_starterChecked) return;
    _starterChecked = true;
    await InventoryService.ensureStarterInventory(hero);
  }

  EquipmentModel _getOwnedEquippedItem({
    required List<InventoryEntry> inventory,
    required String type,
    required String? equippedId,
    required EquipmentModel fallback,
  }) {
    if (equippedId == null || equippedId.isEmpty) return fallback;
    for (final entry in inventory) {
      if (entry.equipment.type == type && entry.equipment.id == equippedId) {
        return entry.equipment;
      }
    }
    return fallback;
  }

  // --- STAT CALCULATORS ---
  int currentStr(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) =>
      (hero?.strength ?? 10) +
      (weapon.statModifiers['STR'] ?? 0) +
      (armor.statModifiers['STR'] ?? 0) +
      (pet.statModifiers['STR'] ?? 0);
  int currentInt(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) =>
      (hero?.intellect ?? 10) +
      (weapon.statModifiers['INT'] ?? 0) +
      (armor.statModifiers['INT'] ?? 0) +
      (pet.statModifiers['INT'] ?? 0);
  int currentSpi(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) =>
      (hero?.spirit ?? 10) +
      (weapon.statModifiers['SPI'] ?? 0) +
      (armor.statModifiers['SPI'] ?? 0) +
      (pet.statModifiers['SPI'] ?? 0);
  int currentAgi(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) =>
      (hero?.agility ?? 10) +
      (weapon.statModifiers['AGI'] ?? 0) +
      (armor.statModifiers['AGI'] ?? 0) +
      (pet.statModifiers['AGI'] ?? 0);
  int maxHp(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) => (hero?.maxHp ?? 100) + weapon.hpBonus + armor.hpBonus + pet.hpBonus;
  int currentHp(
    HeroModel? hero,
    EquipmentModel weapon,
    EquipmentModel armor,
    EquipmentModel pet,
  ) => (hero?.hp ?? 100) + weapon.hpBonus + armor.hpBonus + pet.hpBonus;

  @override
  Widget build(BuildContext context) {
    if (_heroUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF9F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
        ),
      );
    }

    return StreamBuilder<HeroModel?>(
      stream: AuthService.getHeroStream(_heroUid!),
      builder: (context, snapshot) {
        final hero = snapshot.data;
        if (hero == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFFCF9F0),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            ),
          );
        }

        _ensureStarterInventory(hero);

        return StreamBuilder<List<InventoryEntry>>(
          stream: InventoryService.inventoryEntriesStream(hero.uid),
          builder: (context, inventorySnapshot) {
            final inventory = inventorySnapshot.data ?? [];
            final equippedWeapon = _getOwnedEquippedItem(
              inventory: inventory,
              type: 'WEAPON',
              equippedId: hero.equippedWeaponId,
              fallback: _defaultWeapon,
            );
            final equippedArmor = _getOwnedEquippedItem(
              inventory: inventory,
              type: 'ARMOR',
              equippedId: hero.equippedArmorId,
              fallback: _defaultArmor,
            );
            final equippedPet = _getOwnedEquippedItem(
              inventory: inventory,
              type: 'PET',
              equippedId: hero.equippedPetId,
              fallback: _defaultPet,
            );
            final hpMax = maxHp(
              hero,
              equippedWeapon,
              equippedArmor,
              equippedPet,
            );
            final hpCurrent = currentHp(
              hero,
              equippedWeapon,
              equippedArmor,
              equippedPet,
            );

            return Scaffold(
              backgroundColor: const Color(0xFFFCF9F0),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- ADVENTURER STATS BOX (HP / MP / SP / EXP) ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F3EA),
                          border: Border.all(
                            color: const Color(0xFF1C1C17),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF1C1C17),
                              offset: Offset(6, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ADVENTURER STATS",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildProgressBar(
                              "HP [HEALTH POINTS]",
                              "${_formatGold(hpCurrent)} / ${_formatGold(hpMax)}",
                              hpMax > 0 ? (hpCurrent / hpMax) : 0.0,
                              const Color(0xFFBA1A1A),
                            ),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                              "MP [MANA POINTS]",
                              "${_formatGold(hero.mana)} / ${_formatGold(hero.maxMana)}",
                              hero.maxMana > 0 ? hero.mana / hero.maxMana : 0.0,
                              const Color(0xFF1976D2), // Blue for Mana
                            ),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                              "SP [STAMINA]",
                              "${_formatGold(hero.stamina)} / ${_formatGold(hero.maxStamina)}",
                              hero.maxStamina > 0
                                  ? hero.stamina / hero.maxStamina
                                  : 0.0,
                              const Color(0xFF1B6D24),
                            ),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                              "EXP [LEVEL ${hero.level}]",
                              "${_formatGold(hero.exp)} / ${_formatGold(hero.level * 1000)}",
                              hero.level > 0
                                  ? (hero.exp / (hero.level * 1000))
                                  : 0.0,
                              const Color(0xFFD4AF37),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- HERO PORTRAIT & EQUIPMENT ZONE ---
                    _buildHeroEquipmentZone(
                      hero,
                      equippedWeapon,
                      equippedArmor,
                      equippedPet,
                    ),
                    const SizedBox(height: 24),

                    // --- ATTRIBUTES GRID ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.45,
                        children: [
                          _buildStatCard(
                            "STRENGTH",
                            currentStr(
                              hero,
                              equippedWeapon,
                              equippedArmor,
                              equippedPet,
                            ),
                            const Color(0xFFBA1A1A),
                            hero.strength,
                          ),
                          _buildStatCard(
                            "INTELLECT",
                            currentInt(
                              hero,
                              equippedWeapon,
                              equippedArmor,
                              equippedPet,
                            ),
                            const Color(0xFF6D4C41),
                            hero.intellect,
                          ),
                          _buildStatCard(
                            "SPIRIT",
                            currentSpi(
                              hero,
                              equippedWeapon,
                              equippedArmor,
                              equippedPet,
                            ),
                            const Color(0xFFD4AF37),
                            hero.spirit,
                          ),
                          _buildStatCard(
                            "AGILITY",
                            currentAgi(
                              hero,
                              equippedWeapon,
                              equippedArmor,
                              equippedPet,
                            ),
                            const Color(0xFF455A64),
                            hero.agility,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- FAMILY JOIN SECTION ---
                    if (hero.guardianId == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _buildFamilyJoinSection(),
                      ),
                    if (hero.guardianId == null) const SizedBox(height: 24),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  // --- PROGRESS BAR ---
  Widget _buildProgressBar(
    String label,
    String value,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 18,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFDCD8CF), // Hollow square box color
            border: Border.all(color: const Color(0xFF1C1C17), width: 3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(
              color: color, // Solid color fill without border
            ),
          ),
        ),
      ],
    );
  }

  // --- HERO & EQUIPMENT ZONE ---
  Widget _buildHeroEquipmentZone(
    HeroModel hero,
    EquipmentModel equippedWeapon,
    EquipmentModel equippedArmor,
    EquipmentModel equippedPet,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // --- BOX CHỨA 3 SLOT TRANG BỊ ---
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3EA),
              border: Border.all(color: const Color(0xFF1C1C17), width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0xFF1C1C17), offset: Offset(6, 6)),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // TRÁI: Armor (cao toàn bộ)
                  Expanded(
                    child: _buildEquipSlot(
                      heroUid: hero.uid,
                      label: "ARMOR",
                      labelColor: const Color(0xFF455A64),
                      emptyIcon: Icons.shield_outlined,
                      item: equippedArmor,
                      tabIndex: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // PHẢI: Weapon (trên) + Pet (dưới)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildEquipSlot(
                            heroUid: hero.uid,
                            label: "WEAPON",
                            labelColor: const Color(0xFFBA1A1A),
                            emptyIcon: Icons.gavel_outlined,
                            item: equippedWeapon,
                            tabIndex: 0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _buildEquipSlot(
                            heroUid: hero.uid,
                            label: "PET",
                            labelColor: const Color(0xFFD4AF37),
                            emptyIcon: Icons.pets_outlined,
                            item: equippedPet,
                            tabIndex: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // --- HỘP VÀNG ---
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF1C1C17), width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFFD4AF37),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatGold(hero.gold),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1C17),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Một ô slot trang bị (Armor / Weapon / Pet) trong box trang bị.
  /// Bấm vào sẽ mở Inventory ở đúng tab tương ứng.
  Widget _buildEquipSlot({
    required String heroUid,
    required String label,
    required Color labelColor,
    required IconData emptyIcon,
    required EquipmentModel item,
    required int tabIndex,
  }) {
    final bool isEmpty = item.id.isEmpty;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryScreen(
              heroUid: heroUid,
              initialTabIndex: tabIndex,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C17),
          border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        ),
        child: Column(
          children: [
            // Nhãn slot
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
            // Hình trang bị
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: isEmpty
                    ? Center(
                        child: Icon(
                          emptyIcon,
                          size: 36,
                          color: Colors.white24,
                        ),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          emptyIcon,
                          size: 36,
                          color: Colors.white24,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ATTRIBUTE CARD ---
  Widget _buildStatCard(String label, int value, Color barColor, int baseVal) {
    final int extra = value - baseVal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF7F7663),
              letterSpacing: 0.8,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$value",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C1C17),
                  height: 1.0,
                ),
              ),
              if (extra > 0) ...[
                const SizedBox(width: 4),
                Text(
                  "+$extra",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37), // Gold colored bonus
                  ),
                ),
              ],
            ],
          ),
          Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E2DA),
                  border: Border.all(color: const Color(0xFF1C1C17), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: value,
                      child: Container(color: barColor),
                    ),
                    Expanded(
                      flex: (60 - value).clamp(1, 60),
                      child: Container(color: Colors.transparent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FAMILY JOIN SECTION ---
  Widget _buildFamilyJoinSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA), // Container base layer
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom,
                color: Color(0xFF1C1C17),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "JOIN A FAMILY",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C1C17),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Enter the unique invite code from your guardian to link your account.",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7F7663),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF1C1C17),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF1C1C17),
                    ),
                    decoration: InputDecoration(
                      hintText: 'ENTER CODE',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFDCD8CF),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLinking ? null : _joinFamily,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1C1C17),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    side: const BorderSide(color: Color(0xFF1C1C17), width: 2),
                  ),
                  child: _isLinking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF1C1C17),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "JOIN",
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _joinFamily() async {
    final code = _inviteCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLinking = true);

    try {
      final account = await AuthService.getCurrentAccount();
      if (account == null) throw Exception("Bạn chưa đăng nhập.");

      await AuthService.linkHeroByInviteCode(
        heroUid: account.uid,
        inviteCode: code,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tham gia Family thành công!'),
          backgroundColor: Color(0xFF1C1C17),
        ),
      );
      _inviteCodeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  // --- UTILS ---
  String _formatGold(int num) {
    if (num >= 1000) {
      final str = num.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = str.length - 1; i >= 0; i--) {
        buffer.write(str[i]);
        count++;
        if (count % 3 == 0 && i != 0) {
          buffer.write(',');
        }
      }
      return buffer.toString().split('').reversed.join('');
    }
    return num.toString();
  }
}
