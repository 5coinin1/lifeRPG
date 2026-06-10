import 'package:cloud_firestore/cloud_firestore.dart';

import 'level_model.dart';

class HeroModel {
  final String uid;
  final String displayName;
  final String email;
  final String characterPath; // 'STR', 'INT', 'SPI', 'AGI'
  final int level;
  final int exp;
  final int hp;
  final int stamina;
  final int mana;
  final int maxHp;
  final int maxMana;
  final int maxStamina;
  final int strength;
  final int agility;
  final int intellect;
  final int spirit;
  final int gold;
  final String? guardianId; // UID của phụ huynh (null nếu chưa có)
  final String? guildId; // UID của Guild (null nếu chưa có)
  final String title;
  final String status; // 'active' or 'reviving'
  final DateTime? reviveUntil;
  final DateTime? lastResourceRefreshAt;
  final DateTime createdAt;

  // Equipped item IDs
  final String? equippedWeaponId;
  final String? equippedArmorId;
  final String? equippedPetId;

  // Accumulated unassigned stat points
  final int statPoints;

  HeroModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.characterPath,
    this.level = 1,
    this.exp = 0,
    this.hp = 100,
    this.stamina = 100,
    this.mana = 100,
    this.maxHp = 100,
    this.maxMana = 100,
    this.maxStamina = 100,
    this.strength = 10,
    this.agility = 10,
    this.intellect = 10,
    this.spirit = 10,
    this.gold = 100,
    this.guardianId,
    this.guildId,
    this.title = 'Novice',
    this.status = 'active',
    this.reviveUntil,
    this.lastResourceRefreshAt,
    required this.createdAt,
    this.equippedWeaponId,
    this.equippedArmorId,
    this.equippedPetId,
    this.statPoints = 0,
  });

  factory HeroModel.fromMap(Map<String, dynamic> map) {
    final level = (map['level'] as num?)?.toInt() ?? 1;
    return HeroModel(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      characterPath: map['characterPath'] as String? ?? 'STR',
      level: level,
      exp: (map['exp'] as num?)?.toInt() ?? 0,
      hp: (map['hp'] as num?)?.toInt() ?? 100,
      stamina: (map['stamina'] as num?)?.toInt() ?? 100,
      mana: (map['mana'] as num?)?.toInt() ?? 100,
      // maxHp/maxMana/maxStamina: nếu doc cũ chưa có thì suy ra từ level
      maxHp: (map['maxHp'] as num?)?.toInt() ?? LevelModel.maxHpForLevel(level),
      maxMana:
          (map['maxMana'] as num?)?.toInt() ?? LevelModel.maxManaForLevel(level),
      maxStamina: (map['maxStamina'] as num?)?.toInt() ??
          LevelModel.maxStaminaForLevel(level),
      strength:
          (map['strength'] as num?)?.toInt() ??
          (map['attributes']?['str'] as num?)?.toInt() ??
          10,
      agility:
          (map['agility'] as num?)?.toInt() ??
          (map['attributes']?['agi'] as num?)?.toInt() ??
          10,
      intellect:
          (map['intellect'] as num?)?.toInt() ??
          (map['attributes']?['int'] as num?)?.toInt() ??
          10,
      spirit:
          (map['spirit'] as num?)?.toInt() ??
          (map['attributes']?['spi'] as num?)?.toInt() ??
          10,
      gold: (map['gold'] as num?)?.toInt() ?? 100,
      guardianId: map['guardianId'] as String?,
      guildId: map['guildId'] as String?,
      title: map['title'] as String? ?? 'Novice',
      status: map['status'] as String? ?? 'active',
      reviveUntil: (map['reviveUntil'] as Timestamp?)?.toDate(),
      lastResourceRefreshAt: (map['lastResourceRefreshAt'] as Timestamp?)
          ?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      equippedWeaponId: map['equippedWeaponId'] as String?,
      equippedArmorId: map['equippedArmorId'] as String?,
      equippedPetId: map['equippedPetId'] as String?,
      statPoints: (map['statPoints'] as num?)?.toInt() ?? 0,
    );
  }

  factory HeroModel.fromDoc(DocumentSnapshot doc) {
    final data = Map<String, dynamic>.from(doc.data() as Map);
    data['uid'] = doc.id;
    return HeroModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'characterPath': characterPath,
      'level': level,
      'exp': exp,
      'hp': hp,
      'stamina': stamina,
      'mana': mana,
      'maxHp': maxHp,
      'maxMana': maxMana,
      'maxStamina': maxStamina,
      'strength': strength,
      'agility': agility,
      'intellect': intellect,
      'spirit': spirit,
      'gold': gold,
      'guardianId': guardianId,
      'guildId': guildId,
      'title': title,
      'status': status,
      'reviveUntil': reviveUntil == null
          ? null
          : Timestamp.fromDate(reviveUntil!),
      'lastResourceRefreshAt': lastResourceRefreshAt == null
          ? null
          : Timestamp.fromDate(lastResourceRefreshAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'equippedWeaponId': equippedWeaponId,
      'equippedArmorId': equippedArmorId,
      'equippedPetId': equippedPetId,
      'statPoints': statPoints,
    };
  }

  HeroModel copyWith({
    String? displayName,
    String? characterPath,
    int? level,
    int? exp,
    int? hp,
    int? stamina,
    int? mana,
    int? maxHp,
    int? maxMana,
    int? maxStamina,
    int? strength,
    int? agility,
    int? intellect,
    int? spirit,
    int? gold,
    String? guardianId,
    String? guildId,
    String? title,
    String? status,
    DateTime? reviveUntil,
    DateTime? lastResourceRefreshAt,
    String? equippedWeaponId,
    String? equippedArmorId,
    String? equippedPetId,
    int? statPoints,
  }) {
    return HeroModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      characterPath: characterPath ?? this.characterPath,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      hp: hp ?? this.hp,
      stamina: stamina ?? this.stamina,
      mana: mana ?? this.mana,
      maxHp: maxHp ?? this.maxHp,
      maxMana: maxMana ?? this.maxMana,
      maxStamina: maxStamina ?? this.maxStamina,
      strength: strength ?? this.strength,
      agility: agility ?? this.agility,
      intellect: intellect ?? this.intellect,
      spirit: spirit ?? this.spirit,
      gold: gold ?? this.gold,
      guardianId: guardianId ?? this.guardianId,
      guildId: guildId ?? this.guildId,
      title: title ?? this.title,
      status: status ?? this.status,
      reviveUntil: reviveUntil ?? this.reviveUntil,
      lastResourceRefreshAt:
          lastResourceRefreshAt ?? this.lastResourceRefreshAt,
      createdAt: createdAt,
      equippedWeaponId: equippedWeaponId ?? this.equippedWeaponId,
      equippedArmorId: equippedArmorId ?? this.equippedArmorId,
      equippedPetId: equippedPetId ?? this.equippedPetId,
      statPoints: statPoints ?? this.statPoints,
    );
  }
}
