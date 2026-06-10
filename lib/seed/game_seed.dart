import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/level_model.dart';

class GameSeed {
  // 1. TẠO DATA LEVEL (1 - 50)
  static List<Map<String, dynamic>> generateLevels() {
    return List.generate(50, (index) {
      int level = index + 1;
      // Đường cong EXP: level càng cao cần càng nhiều EXP
      int expRequired = (level * 1000) + (level * level * 50);
      // Điểm cộng chỉ số (Stat points): mỗi level được 3 điểm, các mốc 10, 20, 30... được 10 điểm
      int statPointsReward = (level % 10 == 0) ? 10 : 3;
      // Vàng thưởng khi lên cấp
      int goldReward = level * 250;

      List<String> unlocks = [];
      if (level == 15) unlocks.add('TIER_1_EQUIPMENT');
      if (level == 30) unlocks.add('TIER_2_EQUIPMENT');
      if (level == 40) unlocks.add('TIER_3_EQUIPMENT');

      return {
        'level': level,
        'expRequired': expRequired,
        'statPointsReward': statPointsReward,
        'goldReward': goldReward,
        'maxHp': LevelModel.maxHpForLevel(level),
        'maxMana': LevelModel.maxManaForLevel(level),
        'maxStamina': LevelModel.maxStaminaForLevel(level),
        'unlocks': unlocks,
      };
    });
  }

  // 2. TẠO DATA TRANG BỊ & PET (Tier 0: Lv1, Tier 1: Lv15, Tier 2: Lv30, Tier 3: Lv40)
  static List<Map<String, dynamic>> get equipments => [
    // ==========================================
    // WEAPONS - STRENGTH (STR)
    // ==========================================
    {
      'id': 'w_str_0',
      'name': 'Rusted Anchor',
      'type': 'WEAPON',
      'rarity': 'COMMON',
      'tier': 0,
      'requiredLevel': 1,
      'statModifiers': {'STR': 6, 'AGI': -1},
      'hpBonus': 15,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f696240e3l0i1p2l8nsbm1tuf3kq.png',
      'description':
          'A rusty ship anchor wielded as a weapon. Deals piercing damage with brute force.',
    },
    {
      'id': 'w_str_1',
      'name': 'Beastclaw Greathammer',
      'type': 'WEAPON',
      'rarity': 'LEGENDARY',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'STR': 22, 'SPI': 5},
      'hpBonus': 40,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69aff56dl0i1przmnvkw34pmvm.png',
      'description':
          'Greathammer with five beastly claws. Imbued with the primeval power of beasts.',
    },
    {
      'id': 'w_str_2',
      'name': 'Dragon Greatclaw',
      'type': 'WEAPON',
      'rarity': 'LEGENDARY',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'STR': 50, 'AGI': -5},
      'hpBonus': 100,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69469b4bl0i1oo41w96vla79ii.png',
      'description':
          'Weapon whittled from the claw of a great ancient dragon. Imbued with lightning.',
    },
    {
      'id': 'w_str_3',
      'name': 'Giant-Crusher',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'STR': 110, 'AGI': -15},
      'hpBonus': 300,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f698d50ael0i1ooor7m3e3wm1ksn.png',
      'description':
          'A hammer made from a boulder, used in the War against the Giants. Requires immense strength.',
    },
    {
      'id': 'w_str_4',
      'name': 'Ancient Meteoric Ore Greatsword',
      'type': 'WEAPON',
      'rarity': 'MYTHIC',
      'tier': 4,
      'requiredLevel': 50,
      'statModifiers': {'STR': 150, 'INT': 30},
      'hpBonus': 500,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/ancient_meteoric_ore_greatsword_weapon_elden_ring_wiki_guide_200px.png',
      'description':
          'Forged from meteoric ore, harboring ancient cosmic power. It pierces the heavens.',
    },

    // ==========================================
    // WEAPONS - INTELLECT (INT)
    // ==========================================
    {
      'id': 'w_int_0',
      'name': 'Staff of the Guilty',
      'type': 'WEAPON',
      'rarity': 'COMMON',
      'tier': 0,
      'requiredLevel': 1,
      'statModifiers': {'INT': 5, 'SPI': 2},
      'hpBonus': 0,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f698cdcd5l0i1p17cuvrv89tk1t.png',
      'description':
          'A smoldering staff wielded by the guilty. Boosts blood thorn sorceries.',
    },
    {
      'id': 'w_int_1',
      'name': 'Meteorite Staff',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'INT': 25, 'STR': 2},
      'hpBonus': 10,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f6995e6eel0i1p0ujryl4uvjkiji.png',
      'description':
          'Staff embedded with dark purple meteoric glintstone. Enhances gravity magic.',
    },
    {
      'id': 'w_int_2',
      'name': 'Prince of Death\'s Staff',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'INT': 45, 'SPI': 45},
      'hpBonus': 20,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/prince_of_deaths_staff_weapon_elden_ring_wiki_guide_200px.png',
      'description':
          'Staff embedded with tainted amber. Scales sorcery with both intelligence and faith.',
    },
    {
      'id': 'w_int_3',
      'name': 'Staff of the Great Beyond',
      'type': 'WEAPON',
      'rarity': 'MYTHIC',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'INT': 120, 'SPI': 15},
      'hpBonus': 50,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/staff_of_the_great_beyond_weapon_elden_ring_wiki_guide_200px.webp',
      'description':
          'Channels the primeval current and the deepest cosmos. The pinnacle of glintstone sorcery.',
    },

    // ==========================================
    // WEAPONS - SPIRIT (SPI) -> Seals
    // ==========================================
    {
      'id': 'w_spi_0',
      'name': 'Frenzied Flame Seal',
      'type': 'WEAPON',
      'rarity': 'COMMON',
      'tier': 0,
      'requiredLevel': 1,
      'statModifiers': {'SPI': 5, 'STR': 2, 'INT': 2, 'AGI': 2},
      'hpBonus': 0,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69885c93l0i1pihpfc550piu1x.png',
      'description':
          'Seal marked by the Three Fingers. Enhances frenzied flame incantations.',
    },
    {
      'id': 'w_spi_1',
      'name': 'Dragon Communion Seal',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'SPI': 25, 'STR': 5},
      'hpBonus': 30,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f697307d1l0i1pi6qvgmp5wuhmk.png',
      'description':
          'Formless seal painted with dragon blood. Boosts dragon communion rituals.',
    },
    {
      'id': 'w_spi_2',
      'name': 'Godslayer\'s Seal',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'SPI': 55, 'STR': 5},
      'hpBonus': 50,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69bbd392l0i1ph9qxgols7hl7qc.png',
      'description':
          'Sacred seal of the Godskin Apostles. Enhances godslayer incantations.',
    },
    {
      'id': 'w_spi_3',
      'name': 'Golden Order Seal',
      'type': 'WEAPON',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'SPI': 100, 'INT': 50},
      'hpBonus': 80,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69d76aa8l0i1phsgjq5azzb5g1.png',
      'description':
          'A flawless seal depicting the Golden Order. Scales with intellect and faith perfectly.',
    },

    // ==========================================
    // WEAPONS - AGILITY (AGI) -> Bows/Daggers
    // ==========================================
    {
      'id': 'w_agi_0',
      'name': 'Serpent Bow',
      'type': 'WEAPON',
      'rarity': 'COMMON',
      'tier': 0,
      'requiredLevel': 1,
      'statModifiers': {'AGI': 7, 'STR': 1},
      'hpBonus': 0,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f694c87afl0i1ojvhpi9w9ttf21.png',
      'description':
          'A bow crafted in the shape of two venomous serpents. Imbues arrows with poison.',
    },
    {
      'id': 'w_agi_1',
      'name': 'Magma Blade',
      'type': 'WEAPON',
      'rarity': 'RARE',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'AGI': 20, 'STR': 10},
      'hpBonus': 20,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69908917l0i1os577fp2a0c8n8w.png',
      'description':
          'Curved sword formed of magma. Deals continuous fire damage.',
    },
    {
      'id': 'w_agi_2',
      'name': 'Black Knife',
      'type': 'WEAPON',
      'rarity': 'LEGENDARY',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'AGI': 45, 'SPI': 15},
      'hpBonus': 0,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f69bb7d32l0i1ou85ft99zwecdel.png',
      'description':
          'Dagger wielded by the Black Knife Assassins. Infused with the Rune of Death.',
    },
    {
      'id': 'w_agi_3',
      'name': 'Erdtree Bow',
      'type': 'WEAPON',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'AGI': 90, 'SPI': 30},
      'hpBonus': 50,
      'imageUrl':
          'https://eldenring.fanapis.com/images/weapons/17f6968148cl0i1ojrunt1o8v6y34f.png',
      'description':
          'A majestic bow originating from the Erdtree itself. Fires holy arrows with unmatched speed.',
    },

    // ==========================================
    // ARMOR - STARTER
    // ==========================================
    {
      'id': 'a_common_0',
      'name': 'Cloth Tunic',
      'type': 'ARMOR',
      'rarity': 'COMMON',
      'tier': 0,
      'requiredLevel': 1,
      'statModifiers': {'SPI': 1, 'AGI': 1},
      'hpBonus': 10,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/cloth-grab-elden-ring-wiki-guide-200px.png',
      'description':
          'A plain cloth tunic for new adventurers. Light, simple, and easy to move in.',
    },

    // ==========================================
    // ARMOR - STRENGTH (STR) -> Heavy armor
    // ==========================================
    {
      'id': 'a_str_1',
      'name': 'Knight Armor',
      'type': 'ARMOR',
      'rarity': 'COMMON',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'STR': 10, 'AGI': -2},
      'hpBonus': 80,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/knight_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Reliable iron plate armor for front-line fighters. Heavy, stable, and protective.',
    },
    {
      'id': 'a_str_2',
      'name': 'Banished Knight Armor',
      'type': 'ARMOR',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'STR': 22, 'SPI': 4, 'AGI': -4},
      'hpBonus': 160,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/banished_knight_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Thick armor worn by exiled knights. Built for endurance under brutal pressure.',
    },
    {
      'id': 'a_str_3',
      'name': 'Tree Sentinel Armor',
      'type': 'ARMOR',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'STR': 42, 'SPI': 10, 'AGI': -8},
      'hpBonus': 280,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/tree_sentinel_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Golden armor of an Erdtree champion. Grants massive resilience and sacred presence.',
    },
    {
      'id': 'a_str_4',
      'name': 'Lionel\'s Armor',
      'type': 'ARMOR',
      'rarity': 'MYTHIC',
      'tier': 4,
      'requiredLevel': 50,
      'statModifiers': {'STR': 70, 'SPI': 15, 'AGI': -15},
      'hpBonus': 450,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/lionels_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Massive rounded armor for an unbreakable guardian. Nearly impossible to knock down.',
    },

    // ==========================================
    // ARMOR - INTELLECT (INT) -> Mage robes
    // ==========================================
    {
      'id': 'a_int_1',
      'name': 'Astrologer Robe',
      'type': 'ARMOR',
      'rarity': 'COMMON',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'INT': 10, 'SPI': 3},
      'hpBonus': 30,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/astrologer_robe_elden_ring_wiki_guide_200px.png',
      'description':
          'A robe used by star-readers. Light protection with strong magical focus.',
    },
    {
      'id': 'a_int_2',
      'name': 'Raya Lucarian Robe',
      'type': 'ARMOR',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'INT': 24, 'SPI': 6},
      'hpBonus': 70,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/raya_lucarian_robe_elden_ring_wiki_guide_200px.png',
      'description':
          'Scholarly robe of the academy. Strengthens disciplined spellcasting and study.',
    },
    {
      'id': 'a_int_3',
      'name': 'Snow Witch Robe',
      'type': 'ARMOR',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'INT': 48, 'SPI': 12},
      'hpBonus': 120,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/snow_witch_robe_elden_ring_wiki_guide_200px.png',
      'description':
          'Cold blue robe tied to lunar sorcery. Enhances calm focus and arcane control.',
    },
    {
      'id': 'a_int_4',
      'name': 'Lusat\'s Robe',
      'type': 'ARMOR',
      'rarity': 'MYTHIC',
      'tier': 4,
      'requiredLevel': 50,
      'statModifiers': {'INT': 80, 'SPI': 18, 'STR': -3},
      'hpBonus': 180,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/lusats_robe_elden_ring_wiki_guide_200px.png',
      'description':
          'Primeval sorcerer robe overflowing with cosmic insight. Fragile, but extremely powerful.',
    },

    // ==========================================
    // ARMOR - SPIRIT (SPI) -> Colorful sacred armor
    // ==========================================
    {
      'id': 'a_spi_1',
      'name': 'Confessor Armor',
      'type': 'ARMOR',
      'rarity': 'COMMON',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'SPI': 10, 'AGI': 2},
      'hpBonus': 45,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/confessor_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Dark traveling armor for secretive faithful agents. Balanced defense and conviction.',
    },
    {
      'id': 'a_spi_2',
      'name': 'Noble\'s Traveling Garb',
      'type': 'ARMOR',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'SPI': 24, 'INT': 6},
      'hpBonus': 80,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/nobles_traveling_garb_elden_ring_wiki_guide_200px.png',
      'description':
          'Elegant golden travel garb. A bright outfit for heroes guided by grace and ceremony.',
    },
    {
      'id': 'a_spi_3',
      'name': 'Malenia\'s Armor',
      'type': 'ARMOR',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'SPI': 46, 'AGI': 12},
      'hpBonus': 150,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/malenias_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'A vibrant champion\'s armor with flowing red cloth. Graceful, radiant, and resilient.',
    },
    {
      'id': 'a_spi_4',
      'name': 'Goldmask\'s Rags',
      'type': 'ARMOR',
      'rarity': 'MYTHIC',
      'tier': 4,
      'requiredLevel': 50,
      'statModifiers': {'SPI': 85, 'INT': 25, 'STR': -5},
      'hpBonus': 120,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/goldmasks_rags_elden_ring_wiki_guide_200px.png',
      'description':
          'Radiant sacred rags for absolute faith. Minimal defense, but unmatched spiritual clarity.',
    },

    // ==========================================
    // ARMOR - AGILITY (AGI) -> Light armor
    // ==========================================
    {
      'id': 'a_agi_1',
      'name': 'Leather Armor',
      'type': 'ARMOR',
      'rarity': 'COMMON',
      'tier': 1,
      'requiredLevel': 15,
      'statModifiers': {'AGI': 10, 'STR': 2},
      'hpBonus': 35,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/leather_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Flexible leather armor for quick movement. Good for scouts and duelists.',
    },
    {
      'id': 'a_agi_2',
      'name': 'Black Knife Armor',
      'type': 'ARMOR',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 30,
      'statModifiers': {'AGI': 24, 'SPI': 6},
      'hpBonus': 75,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/black_knife_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Silent armor of assassins. Built for stealth, precision, and fast execution.',
    },
    {
      'id': 'a_agi_3',
      'name': 'Blue Silver Mail Armor',
      'type': 'ARMOR',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 40,
      'statModifiers': {'AGI': 46, 'INT': 12},
      'hpBonus': 130,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/blue_silver_mail_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Light blue mail armor with graceful protection. Swift, elegant, and battle-ready.',
    },
    {
      'id': 'a_agi_4',
      'name': 'Night\'s Cavalry Armor',
      'type': 'ARMOR',
      'rarity': 'MYTHIC',
      'tier': 4,
      'requiredLevel': 50,
      'statModifiers': {'AGI': 78, 'STR': 18},
      'hpBonus': 220,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/nights_cavalry_armor_elden_ring_wiki_guide_200px.png',
      'description':
          'Dark mounted hunter armor. Strong enough for combat, light enough for relentless pursuit.',
    },

    // PET - BOSS RAID DROPS
    {
      'id': 'p_dragonling_1',
      'name': 'Ember Dragonling',
      'type': 'PET',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 20,
      'statModifiers': {'STR': 8, 'INT': 8, 'SPI': 6},
      'hpBonus': 60,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/dragon-heart-elden-ring-wiki-guide.png',
      'description':
          'A small ember dragon born from raid fire. Boosts attack focus and survival.',
    },
    {
      'id': 'p_guardian_wisp_1',
      'name': 'Guardian Wisp',
      'type': 'PET',
      'rarity': 'RARE',
      'tier': 2,
      'requiredLevel': 20,
      'statModifiers': {'SPI': 14, 'INT': 6},
      'hpBonus': 45,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/starlight-shards-elden-ring-wiki-guide.png',
      'description':
          'A calm wisp that follows healers into raids and strengthens recovery magic.',
    },
    {
      'id': 'p_deadline_phoenix_1',
      'name': 'Deadline Phoenix',
      'type': 'PET',
      'rarity': 'LEGENDARY',
      'tier': 3,
      'requiredLevel': 35,
      'statModifiers': {'AGI': 10, 'SPI': 16, 'INT': 10},
      'hpBonus': 120,
      'imageUrl':
          'https://eldenring.wiki.fextralife.com/file/Elden-Ring/phoenix_ashes_elden_ring_wiki_guide.png',
      'description':
          'A rare raid companion that rewards discipline with speed, spirit, and endurance.',
    },
  ];

  static List<Map<String, dynamic>> get bosses => [
    {
      'id': 'procrastination_dragon',
      'name': 'THE PROCRASTINATION DRAGON',
      'phase': 'ENRAGED',
      'maxHp': 10000,
      'bossAttackIntervalMinutes': 60,
      'heroReviveHours': 24,
      'skills': [
        {
          'id': 'ember_mark',
          'name': 'Ember Mark',
          'damage': 18,
          'description':
              'A direct burn on every hero that has attacked the boss.',
        },
        {
          'id': 'tail_crash',
          'name': 'Tail Crash',
          'damage': 28,
          'description': 'A heavy personal strike against active raiders.',
        },
        {
          'id': 'deadline_roar',
          'name': 'Deadline Roar',
          'damage': 40,
          'description': 'The boss punishes raiders who are still in combat.',
        },
      ],
      'lootTable': [
        {'equipmentId': 'w_str_2', 'type': 'WEAPON', 'dropRate': 0.08},
        {'equipmentId': 'w_int_2', 'type': 'WEAPON', 'dropRate': 0.08},
        {'equipmentId': 'w_spi_2', 'type': 'WEAPON', 'dropRate': 0.08},
        {'equipmentId': 'w_agi_2', 'type': 'WEAPON', 'dropRate': 0.08},
        {'equipmentId': 'a_str_2', 'type': 'ARMOR', 'dropRate': 0.06},
        {'equipmentId': 'a_int_2', 'type': 'ARMOR', 'dropRate': 0.06},
        {'equipmentId': 'a_spi_2', 'type': 'ARMOR', 'dropRate': 0.06},
        {'equipmentId': 'a_agi_2', 'type': 'ARMOR', 'dropRate': 0.06},
        {'equipmentId': 'p_dragonling_1', 'type': 'PET', 'dropRate': 0.04},
        {'equipmentId': 'p_guardian_wisp_1', 'type': 'PET', 'dropRate': 0.04},
        {
          'equipmentId': 'p_deadline_phoenix_1',
          'type': 'PET',
          'dropRate': 0.02,
        },
      ],
    },
    // ── BOSS TEST: máu rất thấp để mô phỏng boss chết nhanh ──────────────────
    // 1-2 đòn là hết máu. Loot dropRate 1.0 nên chắc chắn rớt đồ mỗi lần,
    // tiện kiểm tra trọn flow defeated + grant loot + archive event.
    {
      'id': 'test_dummy_boss',
      'name': 'TEST DUMMY (LOW HP)',
      'phase': 'TRAINING',
      'maxHp': 50,
      'bossAttackIntervalMinutes': 60,
      'heroReviveHours': 24,
      'skills': [
        {
          'id': 'poke',
          'name': 'Poke',
          'damage': 1,
          'description': 'A harmless training poke.',
        },
      ],
      'lootTable': [
        {'equipmentId': 'w_str_2', 'type': 'WEAPON', 'dropRate': 1.0},
        {'equipmentId': 'a_str_2', 'type': 'ARMOR', 'dropRate': 1.0},
      ],
    },
  ];

  // ==========================================
  // HÀM ĐỂ SEED LÊN FIREBASE (CHẠY 1 LẦN)
  // ==========================================
  static Future<void> seedToFirestore() async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    // 1. Seed Levels
    final levelsList = generateLevels();
    for (var level in levelsList) {
      final docRef = db.collection('levels').doc(level['level'].toString());
      batch.set(docRef, level);
    }

    // 2. Seed Equipments
    for (var eq in equipments) {
      final docRef = db.collection('equipments').doc(eq['id']);
      batch.set(docRef, eq);
    }

    // 3. Seed Boss Definitions
    for (var boss in bosses) {
      final docRef = db.collection('bosses').doc(boss['id'] as String);
      batch.set(docRef, boss);
    }

    // Commit all
    await batch.commit();
    developer.log('SEED GAME DATA TO FIRESTORE SUCCESSFUL!');
  }
}
