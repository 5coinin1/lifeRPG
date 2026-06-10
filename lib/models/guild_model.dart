import 'package:cloud_firestore/cloud_firestore.dart';

class GuildModel {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String tag;
  final String ownerId; // UID of the Guardian who created the guild
  final List<String> guardianIds; // List of Guardian UIDs in the guild
  final List<String> heroIds; // List of Hero UIDs in the guild
  final List<String> pendingGuardianIds; // Guardians requesting to join
  final List<String> pendingHeroIds; // Heroes requesting to join
  final int level;
  final int exp;
  final int bossHp; // Máu của Boss (default là 4500)
  final DateTime createdAt;

  GuildModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.tag,
    required this.ownerId,
    required this.guardianIds,
    required this.heroIds,
    this.pendingGuardianIds = const [],
    this.pendingHeroIds = const [],
    this.level = 1,
    this.exp = 0,
    this.bossHp = 4500,
    required this.createdAt,
  });

  factory GuildModel.fromMap(Map<String, dynamic> map, String id) {
    return GuildModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'shield',
      tag: map['tag'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      guardianIds: List<String>.from(map['guardianIds'] ?? []),
      heroIds: List<String>.from(map['heroIds'] ?? []),
      pendingGuardianIds: List<String>.from(map['pendingGuardianIds'] ?? []),
      pendingHeroIds: List<String>.from(map['pendingHeroIds'] ?? []),
      level: map['level'] as int? ?? 1,
      exp: map['exp'] as int? ?? 0,
      bossHp: map['bossHp'] as int? ?? 4500,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory GuildModel.fromDoc(DocumentSnapshot doc) {
    return GuildModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'tag': tag,
      'ownerId': ownerId,
      'guardianIds': guardianIds,
      'heroIds': heroIds,
      'pendingGuardianIds': pendingGuardianIds,
      'pendingHeroIds': pendingHeroIds,
      'level': level,
      'exp': exp,
      'bossHp': bossHp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  GuildModel copyWith({
    String? name,
    String? description,
    String? iconName,
    String? tag,
    String? ownerId,
    List<String>? guardianIds,
    List<String>? heroIds,
    List<String>? pendingGuardianIds,
    List<String>? pendingHeroIds,
    int? level,
    int? exp,
    int? bossHp,
  }) {
    return GuildModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      tag: tag ?? this.tag,
      ownerId: ownerId ?? this.ownerId,
      guardianIds: guardianIds ?? this.guardianIds,
      heroIds: heroIds ?? this.heroIds,
      pendingGuardianIds: pendingGuardianIds ?? this.pendingGuardianIds,
      pendingHeroIds: pendingHeroIds ?? this.pendingHeroIds,
      level: level ?? this.level,
      exp: exp ?? this.exp,
      bossHp: bossHp ?? this.bossHp,
      createdAt: createdAt,
    );
  }
}
