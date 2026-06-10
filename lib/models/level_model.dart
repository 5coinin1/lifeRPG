import 'package:cloud_firestore/cloud_firestore.dart';

class LevelModel {
  final int level;
  final int expRequired;
  final int statPointsReward;
  final int goldReward;
  final int maxHp;
  final int maxMana;
  final int maxStamina;
  final List<String> unlocks; // e.g. ['TIER_1_EQUIPMENT']

  LevelModel({
    required this.level,
    required this.expRequired,
    required this.statPointsReward,
    required this.goldReward,
    required this.maxHp,
    required this.maxMana,
    required this.maxStamina,
    required this.unlocks,
  });

  // ─── Công thức chỉ số pool theo level (single source of truth) ───────────────
  // Dùng chung cho seed, đăng ký hero và logic lên cấp để tránh lệch số liệu.
  static int maxHpForLevel(int level) => 100 + (level - 1) * 20;
  static int maxManaForLevel(int level) => 100 + (level - 1) * 10;
  static int maxStaminaForLevel(int level) => 100 + (level - 1) * 8;

  factory LevelModel.fromMap(Map<String, dynamic> map, String docId) {
    final level = (map['level'] as num?)?.toInt() ?? 1;
    return LevelModel(
      level: level,
      expRequired: (map['expRequired'] as num?)?.toInt() ?? 1000,
      statPointsReward: (map['statPointsReward'] as num?)?.toInt() ?? 3,
      goldReward: (map['goldReward'] as num?)?.toInt() ?? 250,
      maxHp: (map['maxHp'] as num?)?.toInt() ?? maxHpForLevel(level),
      maxMana: (map['maxMana'] as num?)?.toInt() ?? maxManaForLevel(level),
      maxStamina:
          (map['maxStamina'] as num?)?.toInt() ?? maxStaminaForLevel(level),
      unlocks: List<String>.from(map['unlocks'] ?? []),
    );
  }

  factory LevelModel.fromDoc(DocumentSnapshot doc) {
    return LevelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'expRequired': expRequired,
      'statPointsReward': statPointsReward,
      'goldReward': goldReward,
      'maxHp': maxHp,
      'maxMana': maxMana,
      'maxStamina': maxStamina,
      'unlocks': unlocks,
    };
  }
}
