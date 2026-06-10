import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'hero_model.dart';

enum RaidSkillEffect { damage, heal, revive }

enum RaidResourceType { stamina, mana, hp, none }

class HeroBattleStats {
  final int strength;
  final int agility;
  final int intellect;
  final int spirit;
  final int level;

  const HeroBattleStats({
    required this.strength,
    required this.agility,
    required this.intellect,
    required this.spirit,
    required this.level,
  });

  factory HeroBattleStats.fromHero(HeroModel hero) {
    return HeroBattleStats(
      strength: hero.strength,
      agility: hero.agility,
      intellect: hero.intellect,
      spirit: hero.spirit,
      level: hero.level,
    );
  }
}

class RaidSkillFormula {
  final double strengthScale;
  final double agilityScale;
  final double intellectScale;
  final double spiritScale;
  final double levelScale;
  final int flat;
  final double multiplier;

  const RaidSkillFormula({
    this.strengthScale = 0,
    this.agilityScale = 0,
    this.intellectScale = 0,
    this.spiritScale = 0,
    this.levelScale = 0,
    this.flat = 0,
    this.multiplier = 1,
  });

  factory RaidSkillFormula.fromMap(Map<String, dynamic> map) {
    return RaidSkillFormula(
      strengthScale: (map['strengthScale'] as num?)?.toDouble() ?? 0,
      agilityScale: (map['agilityScale'] as num?)?.toDouble() ?? 0,
      intellectScale: (map['intellectScale'] as num?)?.toDouble() ?? 0,
      spiritScale: (map['spiritScale'] as num?)?.toDouble() ?? 0,
      levelScale: (map['levelScale'] as num?)?.toDouble() ?? 0,
      flat: (map['flat'] as num?)?.toInt() ?? 0,
      multiplier: (map['multiplier'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strengthScale': strengthScale,
      'agilityScale': agilityScale,
      'intellectScale': intellectScale,
      'spiritScale': spiritScale,
      'levelScale': levelScale,
      'flat': flat,
      'multiplier': multiplier,
    };
  }

  int evaluate(HeroBattleStats stats) {
    final raw =
        flat +
        (stats.strength * strengthScale) +
        (stats.agility * agilityScale) +
        (stats.intellect * intellectScale) +
        (stats.spirit * spiritScale) +
        (stats.level * levelScale);
    return max(0, (raw * multiplier).round());
  }
}

class RaidHeroSkill {
  final String id;
  final String heroId;
  final String guildId;
  final String guildQuestId;
  final String name;
  final String characterPath;
  final String attribute;
  final RaidSkillEffect effect;
  final RaidResourceType resourceType;
  final int resourceCost;
  final RaidSkillFormula formula;
  final String iconKey;
  final int colorValue;
  final bool canTargetAlly;
  final double critChance;
  final double critMultiplier;
  final DateTime? usedAt;

  const RaidHeroSkill({
    required this.id,
    this.heroId = '',
    this.guildId = '',
    this.guildQuestId = '',
    required this.name,
    this.characterPath = '',
    required this.attribute,
    required this.effect,
    required this.resourceType,
    required this.resourceCost,
    required this.formula,
    required this.iconKey,
    required this.colorValue,
    this.canTargetAlly = false,
    this.critChance = 0.15,
    this.critMultiplier = 1.8,
    this.usedAt,
  });

  factory RaidHeroSkill.fromMap(Map<String, dynamic> map, String id) {
    return RaidHeroSkill(
      id: id,
      heroId: map['heroId'] as String? ?? '',
      guildId: map['guildId'] as String? ?? '',
      guildQuestId: map['guildQuestId'] as String? ?? id,
      name: map['name'] as String? ?? 'Guild Skill',
      characterPath: map['characterPath'] as String? ?? '',
      attribute: map['attribute'] as String? ?? 'STRENGTH',
      effect: _effectFromString(map['effect'] as String?),
      resourceType: _resourceFromString(map['resourceType'] as String?),
      resourceCost: (map['resourceCost'] as num?)?.toInt() ?? 10,
      formula: RaidSkillFormula.fromMap(
        Map<String, dynamic>.from(map['formula'] as Map? ?? {}),
      ),
      iconKey: map['iconKey'] as String? ?? 'flash',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFE53935,
      canTargetAlly: map['canTargetAlly'] as bool? ?? false,
      critChance: (map['critChance'] as num?)?.toDouble() ?? 0.15,
      critMultiplier: (map['critMultiplier'] as num?)?.toDouble() ?? 1.8,
      usedAt: (map['usedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heroId': heroId,
      'guildId': guildId,
      'guildQuestId': guildQuestId,
      'name': name,
      'characterPath': characterPath,
      'attribute': attribute,
      'effect': effect.name,
      'resourceType': resourceType.name,
      'resourceCost': resourceCost,
      'formula': formula.toMap(),
      'iconKey': iconKey,
      'colorValue': colorValue,
      'canTargetAlly': canTargetAlly,
      'critChance': critChance,
      'critMultiplier': critMultiplier,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  int evaluate(HeroModel hero) =>
      formula.evaluate(HeroBattleStats.fromHero(hero));

  static RaidSkillEffect _effectFromString(String? value) {
    return RaidSkillEffect.values.firstWhere(
      (effect) => effect.name == value,
      orElse: () => RaidSkillEffect.damage,
    );
  }

  static RaidResourceType _resourceFromString(String? value) {
    return RaidResourceType.values.firstWhere(
      (resource) => resource.name == value,
      orElse: () => RaidResourceType.stamina,
    );
  }
}

class BossSkill {
  final String id;
  final String name;
  final int damage;
  final String description;

  const BossSkill({
    required this.id,
    required this.name,
    required this.damage,
    required this.description,
  });

  factory BossSkill.fromMap(Map<String, dynamic> map) {
    return BossSkill(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      damage: (map['damage'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'damage': damage,
      'description': description,
    };
  }
}

class BossLootDrop {
  final String equipmentId;
  final String type;
  final double dropRate;

  const BossLootDrop({
    required this.equipmentId,
    required this.type,
    required this.dropRate,
  });

  factory BossLootDrop.fromMap(Map<String, dynamic> map) {
    return BossLootDrop(
      equipmentId: map['equipmentId'] as String? ?? '',
      type: map['type'] as String? ?? 'WEAPON',
      dropRate: (map['dropRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'equipmentId': equipmentId, 'type': type, 'dropRate': dropRate};
  }
}

class BossRaidDefinition {
  final String id;
  final String name;
  final String phase;
  final int maxHp;
  final List<BossSkill> skills;
  final List<BossLootDrop> lootTable;
  final Duration bossAttackInterval;
  final Duration heroReviveDuration;

  const BossRaidDefinition({
    required this.id,
    required this.name,
    required this.phase,
    required this.maxHp,
    required this.skills,
    required this.lootTable,
    this.bossAttackInterval = const Duration(hours: 1),
    this.heroReviveDuration = const Duration(days: 1),
  });

  factory BossRaidDefinition.fromMap(Map<String, dynamic> map, String id) {
    return BossRaidDefinition(
      id: id,
      name: map['name'] as String? ?? 'Unknown Boss',
      phase: map['phase'] as String? ?? 'NORMAL',
      maxHp: (map['maxHp'] as num?)?.toInt() ?? 10000,
      skills: (map['skills'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((skill) => BossSkill.fromMap(Map<String, dynamic>.from(skill)))
          .toList(),
      lootTable: (map['lootTable'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((drop) => BossLootDrop.fromMap(Map<String, dynamic>.from(drop)))
          .toList(),
      bossAttackInterval: Duration(
        minutes: (map['bossAttackIntervalMinutes'] as num?)?.toInt() ?? 60,
      ),
      heroReviveDuration: Duration(
        hours: (map['heroReviveHours'] as num?)?.toInt() ?? 24,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phase': phase,
      'maxHp': maxHp,
      'skills': skills.map((skill) => skill.toMap()).toList(),
      'lootTable': lootTable.map((drop) => drop.toMap()).toList(),
      'bossAttackIntervalMinutes': bossAttackInterval.inMinutes,
      'heroReviveHours': heroReviveDuration.inHours,
    };
  }
}

enum GuildEventType { bossRaid, exploration, defense, puzzle }

class GuildEventState {
  final String guildId;
  final String eventId;
  final String eventName;
  final String eventPhase;
  final int maxProgress;
  final int currentProgress;
  final bool isCompleted;
  final GuildEventType type;
  final Map<String, dynamic> customData;

  const GuildEventState({
    required this.guildId,
    required this.eventId,
    required this.eventName,
    required this.eventPhase,
    required this.maxProgress,
    required this.currentProgress,
    this.isCompleted = false,
    this.type = GuildEventType.bossRaid,
    this.customData = const {},
  });

  // Backward-compatibility getters for Boss Raid
  String get bossId => eventId;
  String get bossName => eventName;
  String get bossPhase => eventPhase;
  int get bossMaxHp => maxProgress;
  int get currentHp => currentProgress;
  bool get defeated => isCompleted;
  DateTime? get lastBossAttackAt => customData['lastBossAttackAt'] as DateTime?;

  /// Đọc state generic từ doc `events/{eventId}` — source of truth mới.
  /// Dùng cho mọi loại event (boss raid, exploration, defense, puzzle...).
  factory GuildEventState.fromEventDoc(
    Map<String, dynamic> data,
    String eventDocId,
    String guildId,
  ) {
    final rawCustom = data['customData'];
    final customData = rawCustom is Map
        ? Map<String, dynamic>.from(rawCustom)
        : <String, dynamic>{};
    // Chuyển Timestamp đã biết trong customData thành DateTime cho getter dùng.
    final lastAttack = customData['lastBossAttackAt'];
    if (lastAttack is Timestamp) {
      customData['lastBossAttackAt'] = lastAttack.toDate();
    }
    final maxProgress = (data['maxProgress'] as num?)?.toInt() ?? 0;
    return GuildEventState(
      guildId: guildId,
      // eventId giữ nghĩa "định danh nội dung event" (vd bossId) để getter
      // bossId hoạt động như cũ; doc id thật không cần cho UI hiện tại.
      // Fallback key cũ 'bossId'/'bossName' phòng doc lai trước refactor.
      eventId: (data['definitionId'] as String?) ??
          (data['bossId'] as String?) ??
          eventDocId,
      eventName:
          (data['name'] as String?) ?? (data['bossName'] as String?) ?? 'Event',
      eventPhase: data['phase'] as String? ?? 'NORMAL',
      maxProgress: maxProgress,
      currentProgress:
          (data['currentProgress'] as num?)?.toInt() ?? maxProgress,
      isCompleted:
          data['isCompleted'] as bool? ?? (data['status'] == 'completed'),
      type: _eventTypeFromString(data['type'] as String?),
      customData: customData,
    );
  }

  static GuildEventType _eventTypeFromString(String? value) {
    switch (value) {
      case 'boss_raid':
      case 'bossRaid':
        return GuildEventType.bossRaid;
      case 'exploration':
        return GuildEventType.exploration;
      case 'defense':
        return GuildEventType.defense;
      case 'puzzle':
        return GuildEventType.puzzle;
      default:
        return GuildEventType.bossRaid;
    }
  }

  factory GuildEventState.fromGuildMap(
    Map<String, dynamic> map,
    String guildId,
    BossRaidDefinition boss, // For legacy
  ) {
    return GuildEventState(
      guildId: guildId,
      eventId:
          (map['activeBossId'] as String?) ??
          (map['bossId'] as String?) ??
          boss.id,
      eventName: boss.name,
      eventPhase: boss.phase,
      maxProgress: boss.maxHp,
      currentProgress: (map['bossHp'] as num?)?.toInt() ?? boss.maxHp,
      isCompleted: map['bossDefeated'] as bool? ?? false,
      type: GuildEventType.bossRaid,
      customData: {
        'lastBossAttackAt': (map['lastBossAttackAt'] as Timestamp?)?.toDate(),
      },
    );
  }
}

typedef BossRaidState = GuildEventState;

class EventActionResult {
  final RaidHeroSkill skillUsed;
  final int progressContributed;
  final bool critical;
  final int currentProgress;
  final int heroHp;
  final int heroStamina;
  final int heroMana;
  final bool defeated; // event hoàn thành (boss chết) sau đòn này?
  final List<String> rewards; // equipmentId hero này nhận được khi defeated
  final bool success; // false = đòn đánh bị chặn (vd thiếu mana/stamina)
  final String? message; // lý do khi success == false

  const EventActionResult({
    required this.skillUsed,
    required this.progressContributed,
    required this.critical,
    required this.currentProgress,
    required this.heroHp,
    required this.heroStamina,
    required this.heroMana,
    this.defeated = false,
    this.rewards = const [],
    this.success = true,
    this.message,
  });

  /// Kết quả thất bại (không throw) — dùng cho điều kiện gameplay bình thường
  /// như thiếu tài nguyên, đang hồi sinh... để tránh ném exception.
  factory EventActionResult.failure({
    required RaidHeroSkill skill,
    required String message,
    int heroHp = 0,
    int heroStamina = 0,
    int heroMana = 0,
  }) {
    return EventActionResult(
      skillUsed: skill,
      progressContributed: 0,
      critical: false,
      currentProgress: 0,
      heroHp: heroHp,
      heroStamina: heroStamina,
      heroMana: heroMana,
      success: false,
      message: message,
    );
  }

  EventActionResult copyWith({bool? defeated, List<String>? rewards}) {
    return EventActionResult(
      skillUsed: skillUsed,
      progressContributed: progressContributed,
      critical: critical,
      currentProgress: currentProgress,
      heroHp: heroHp,
      heroStamina: heroStamina,
      heroMana: heroMana,
      defeated: defeated ?? this.defeated,
      rewards: rewards ?? this.rewards,
      success: success,
      message: message,
    );
  }

  // Backward-compatibility getters for Boss Raid
  RaidHeroSkill get skill => skillUsed;
  int get amount => progressContributed;
  int get bossHp => currentProgress;
}

typedef RaidSkillResult = EventActionResult;

/// Thông báo trong app (inbox) cho hero — vd "boss bị tiêu diệt + phần thưởng".
class GameNotification {
  final String id;
  final String type;
  final String title;
  final String guildId;
  final String bossName;
  final List<String> rewards; // equipmentId
  final bool read;
  final DateTime createdAt;

  const GameNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.guildId,
    required this.bossName,
    required this.rewards,
    required this.read,
    required this.createdAt,
  });

  factory GameNotification.fromMap(Map<String, dynamic> map, String id) {
    return GameNotification(
      id: id,
      type: map['type'] as String? ?? 'info',
      title: map['title'] as String? ?? 'NOTIFICATION',
      guildId: map['guildId'] as String? ?? '',
      bossName: map['bossName'] as String? ?? '',
      rewards: List<String>.from(map['rewards'] ?? const []),
      read: map['read'] as bool? ?? false,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
