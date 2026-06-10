// lib/screens/shop_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hero_model.dart';
import '../models/equipment_model.dart';
import '../services/auth_service.dart';
import '../services/inventory_service.dart';

class PotionItem {
  final String id;
  final String name;
  final String description;
  final int cost;
  final String imageUrl;
  final int restoreAmount;
  final String type; // 'MANA', 'STAMINA', 'HP'

  const PotionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.imageUrl,
    required this.restoreAmount,
    required this.type,
  });
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _heroUid;
  bool _isLoading = true;

  // Danh sách các loại thuốc hỗ trợ bán trong shop
  final List<PotionItem> _potions = const [
    PotionItem(
      id: 'pot_hp',
      name: 'Thuốc Hồi Phục HP',
      description: 'Hồi phục lập tức 50 Điểm Sinh Mệnh (HP).',
      cost: 40,
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/potion.png',
      restoreAmount: 50,
      type: 'HP',
    ),
    PotionItem(
      id: 'pot_mana',
      name: 'Thuốc Hồi Phục Mana',
      description: 'Hồi phục lập tức 30 Điểm Năng Lượng (MP).',
      cost: 30,
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/ether.png',
      restoreAmount: 30,
      type: 'MANA',
    ),
    PotionItem(
      id: 'pot_stamina',
      name: 'Thuốc Hồi Phục Stamina',
      description: 'Hồi phục lập tức 30 Điểm Thể Lực (SP).',
      cost: 30,
      imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/elixir.png',
      restoreAmount: 30,
      type: 'STAMINA',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHero();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHero() async {
    final account = await AuthService.getCurrentAccount();
    if (account != null && mounted) {
      setState(() {
        _heroUid = account.uid;
        _isLoading = false;
      });
      await _ensureCommonPetsExist();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Đảm bảo dữ liệu pet common tồn tại trong collection equipments để tránh lỗi khi render
  Future<void> _ensureCommonPetsExist() async {
    final db = FirebaseFirestore.instance;
    final List<Map<String, dynamic>> pets = [
      {
        'id': 'p_common_slime',
        'name': 'Friendly Slime',
        'type': 'PET',
        'rarity': 'COMMON',
        'tier': 0,
        'requiredLevel': 1,
        'statModifiers': {'STR': 1, 'AGI': 1},
        'hpBonus': 10,
        'imageUrl': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',
        'description': 'Một chú slime xanh lá thân thiện, nhảy tưng bừng bên cạnh bạn.'
      },
      {
        'id': 'p_common_cat',
        'name': 'Stray Cat',
        'type': 'PET',
        'rarity': 'COMMON',
        'tier': 0,
        'requiredLevel': 1,
        'statModifiers': {'AGI': 2},
        'hpBonus': 5,
        'imageUrl': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/52.png',
        'description': 'Một chú mèo hoang quấn người đi theo bạn từ quán rượu.'
      },
      {
        'id': 'p_common_dog',
        'name': 'Loyal Puppy',
        'type': 'PET',
        'rarity': 'COMMON',
        'tier': 0,
        'requiredLevel': 1,
        'statModifiers': {'STR': 2},
        'hpBonus': 15,
        'imageUrl': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/104.png',
        'description': 'Một chú cún trung thành luôn hào hứng đồng hành cùng bạn làm nhiệm vụ.'
      }
    ];

    for (var pet in pets) {
      final docRef = db.collection('equipments').doc(pet['id']);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set(pet);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6F3EA),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF1C1C17), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          "LỖI GIAO DỊCH",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFBA1A1A),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1C17),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C17),
              foregroundColor: const Color(0xFFFCF9F0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              "ĐÓNG",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showRetroConfirmDialog({
    required String title,
    required String message,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6F3EA),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF1C1C17), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1C1C17),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4D4635),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "HỦY BO",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7F7663),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C17),
              foregroundColor: const Color(0xFFFCF9F0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "XÁC NHẬN",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _purchaseAndUsePotion(HeroModel hero, PotionItem potion) async {
    if (hero.gold < potion.cost) {
      _showErrorDialog("Bạn không đủ Vàng để mua loại thuốc này!");
      return;
    }

    // Kiểm tra xem chỉ số đã đầy hay chưa trước khi mua uống
    if (potion.type == 'MANA' && hero.mana >= hero.maxMana) {
      _showErrorDialog(
          "Điểm Năng Lượng (MP) của bạn đã đạt mức tối đa (${hero.maxMana})!");
      return;
    }
    if (potion.type == 'STAMINA' && hero.stamina >= hero.maxStamina) {
      _showErrorDialog(
          "Điểm Thể Lực (SP) của bạn đã đạt mức tối đa (${hero.maxStamina})!");
      return;
    }
    if (potion.type == 'HP' && hero.hp >= hero.maxHp) {
      _showErrorDialog("Sinh Mệnh (HP) của bạn đã đạt mức tối đa (${hero.maxHp})!");
      return;
    }

    final confirm = await _showRetroConfirmDialog(
      title: "MUA & SỬ DỤNG",
      message: "Bạn có muốn mua và sử dụng ${potion.name} với giá ${potion.cost} Vàng?",
    );

    if (!confirm) return;

    final db = FirebaseFirestore.instance;
    final heroRef = db.collection('heroes').doc(hero.uid);

    try {
      await db.runTransaction((transaction) async {
        final freshHeroDoc = await transaction.get(heroRef);
        if (!freshHeroDoc.exists) throw Exception("Không tìm thấy Hero!");

        final freshHero = HeroModel.fromMap({
          ...freshHeroDoc.data()!,
          'uid': freshHeroDoc.id,
        });

        if (freshHero.gold < potion.cost) {
          throw Exception("Không đủ vàng!");
        }

        final updates = <String, dynamic>{
          'gold': freshHero.gold - potion.cost,
        };

        if (potion.type == 'MANA') {
          updates['mana'] =
              min(freshHero.maxMana, freshHero.mana + potion.restoreAmount);
        } else if (potion.type == 'STAMINA') {
          updates['stamina'] = min(
              freshHero.maxStamina, freshHero.stamina + potion.restoreAmount);
        } else if (potion.type == 'HP') {
          updates['hp'] = min(freshHero.maxHp, freshHero.hp + potion.restoreAmount);
        }

        transaction.update(heroRef, updates);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã sử dụng ${potion.name}! Hồi phục thành công."),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Giao dịch thất bại: $e");
      }
    }
  }

  Future<void> _purchaseEquipment(
      HeroModel hero, EquipmentModel item, int cost) async {
    if (hero.gold < cost) {
      _showErrorDialog("Bạn không đủ Vàng để mua trang bị này!");
      return;
    }

    final confirm = await _showRetroConfirmDialog(
      title: "MUA TRANG BỊ",
      message: "Bạn có muốn mua ${item.name} với giá $cost Vàng để đưa vào Hòm đồ?",
    );

    if (!confirm) return;

    final db = FirebaseFirestore.instance;
    final heroRef = db.collection('heroes').doc(hero.uid);

    try {
      // 1. Trừ vàng của hero
      await db.runTransaction((transaction) async {
        final freshHeroDoc = await transaction.get(heroRef);
        if (!freshHeroDoc.exists) throw Exception("Không tìm thấy Hero!");

        final freshHero = HeroModel.fromMap({
          ...freshHeroDoc.data()!,
          'uid': freshHeroDoc.id,
        });

        if (freshHero.gold < cost) {
          throw Exception("Không đủ vàng!");
        }

        transaction.update(heroRef, {
          'gold': freshHero.gold - cost,
        });
      });

      // 2. Thêm vật phẩm vào hòm đồ
      await InventoryService.grantItem(
        heroId: hero.uid,
        equipmentId: item.id,
        source: 'shop',
        tradable: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã mua thành công ${item.name}! Hãy vào trang Hero -> Armory để trang bị."),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Giao dịch thất bại: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _heroUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF9F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
        ),
      );
    }

    return StreamBuilder<HeroModel?>(
      stream: AuthService.getHeroStream(_heroUid!),
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

        return Scaffold(
          backgroundColor: const Color(0xFFFCF9F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFCF9F0),
            elevation: 0,
            title: Text(
              'HERO SHOP',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
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
                Tab(text: 'DƯỢC PHẨM (POTIONS)'),
                Tab(text: 'TRANG BỊ & THÚ CƯNG'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Hero Status bar: Hiển thị Vàng hiện có + các thanh chỉ số hiện tại để người dùng thấy thay đổi
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F3EA),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1C1C17), width: 2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFF1C1C17), size: 20),
                            const SizedBox(width: 6),
                            Text(
                              hero.displayName.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1C1C17),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: const Color(0xFF1C1C17),
                              child: Text(
                                "LV. ${hero.level}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Hộp vàng hiện có
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF1C1C17),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "${hero.gold}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1C1C17),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "GOLD",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7F7663),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Thanh năng lượng hiện tại
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniBar(
                            "HP: ${hero.hp}/${hero.maxHp}",
                            hero.hp / hero.maxHp,
                            const Color(0xFFBA1A1A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniBar(
                            "MP: ${hero.mana}/${hero.maxMana}",
                            hero.maxMana > 0 ? hero.mana / hero.maxMana : 0.0,
                            const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniBar(
                            "SP: ${hero.stamina}/${hero.maxStamina}",
                            hero.maxStamina > 0
                                ? hero.stamina / hero.maxStamina
                                : 0.0,
                            const Color(0xFF388E3C),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPotionsTab(hero),
                    _buildEquipmentsTab(hero),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1C1C17),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1C1C17), width: 1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ],
    );
  }

  // TAB 1: Danh sách thuốc hỗ trợ
  Widget _buildPotionsTab(HeroModel hero) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _potions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final potion = _potions[index];
        Color themeColor = const Color(0xFF1C1C17);
        if (potion.type == 'HP') themeColor = const Color(0xFFBA1A1A);
        if (potion.type == 'MANA') themeColor = const Color(0xFF1976D2);
        if (potion.type == 'STAMINA') themeColor = const Color(0xFF388E3C);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF1C1C17),
                offset: Offset(4, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCF9F0),
                  border: Border.all(color: const Color(0xFF1C1C17), width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  potion.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.hourglass_empty),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            potion.name,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1C1C17),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            border: Border.all(color: themeColor, width: 1),
                          ),
                          child: Text(
                            potion.type,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      potion.description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4D4635),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Giá tiền của thuốc
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${potion.cost} Vàng",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1C1C17),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Nút mua & sử dụng lập tức
              SizedBox(
                width: 110,
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF1C1C17), width: 1.5),
                  ),
                  onPressed: () => _purchaseAndUsePotion(hero, potion),
                  child: Text(
                    "MUA & UỐNG",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 2: Danh sách vũ khí & thú cưng common
  Widget _buildEquipmentsTab(HeroModel hero) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hero_inventories')
          .doc(hero.uid)
          .collection('items')
          .snapshots(),
      builder: (context, inventorySnapshot) {
        if (inventorySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
          );
        }

        final ownedIds =
            inventorySnapshot.data?.docs.map((doc) => doc.id).toSet() ?? {};

        return StreamBuilder<List<EquipmentModel>>(
          stream: FirebaseFirestore.instance
              .collection('equipments')
              .where('rarity', isEqualTo: 'COMMON')
              .snapshots()
              .map((snap) =>
                  snap.docs.map((doc) => EquipmentModel.fromDoc(doc)).toList()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
              );
            }

            final allItems = snapshot.data ?? [];
            final items = allItems
                .where((item) =>
                    (item.type == 'WEAPON' || item.type == 'PET') &&
                    !ownedIds.contains(item.id))
                .toList();

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Bạn đã sở hữu tất cả trang bị trong cửa hàng!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7F7663),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                final isPet = item.type == 'PET';
                final cost = isPet ? 200 : 150;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF1C1C17), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh item
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isPet
                              ? const Color(0xFFFCF9F0)
                              : const Color(0xFF1C1C17),
                          border:
                              Border.all(color: const Color(0xFF1C1C17), width: 2),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(
                            isPet ? Icons.pets : Icons.gavel,
                            color: isPet
                                ? const Color(0xFF7F7663)
                                : Colors.white24,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nội dung
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên + badge loại
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  color: const Color(0xFFD4AF37),
                                  child: Text(
                                    item.type,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1C1C17),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF4D4635),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Chỉ số
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...item.statModifiers.entries.map((entry) {
                                  final isPositive = entry.value >= 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
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
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isPositive
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFC62828),
                                      ),
                                    ),
                                  );
                                }),
                                if (item.hpBonus > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      border: Border.all(
                                          color: const Color(0xFFE57373)),
                                    ),
                                    child: Text(
                                      '+${item.hpBonus} HP',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Giá tiền
                            Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Color(0xFFD4AF37), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$cost Vàng',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF1C1C17),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút mua
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C17),
                            foregroundColor: const Color(0xFFFCF9F0),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _purchaseEquipment(hero, item, cost),
                          child: Text(
                            'MUA',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}