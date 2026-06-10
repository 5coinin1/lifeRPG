import 'package:cloud_firestore/cloud_firestore.dart';

class EquipmentModel {
  final String id;
  final String name;
  final String type; // 'WEAPON', 'ARMOR', 'PET'
  final String rarity; // 'COMMON', 'UNCOMMON', 'RARE', 'LEGENDARY'
  final int tier; // 0, 1, 2, 3
  final int requiredLevel;
  final Map<String, int> statModifiers; // e.g. {'STR': 10, 'AGI': -2}
  final int hpBonus;
  final String imageUrl;
  final String description;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.tier,
    required this.requiredLevel,
    required this.statModifiers,
    required this.hpBonus,
    required this.imageUrl,
    required this.description,
  });

  factory EquipmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return EquipmentModel(
      id: docId,
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'WEAPON',
      rarity: map['rarity'] as String? ?? 'COMMON',
      tier: (map['tier'] as num?)?.toInt() ?? 0,
      requiredLevel: (map['requiredLevel'] as num?)?.toInt() ?? 1,
      statModifiers: Map<String, int>.from(map['statModifiers'] ?? {}),
      hpBonus: (map['hpBonus'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }

  factory EquipmentModel.fromDoc(DocumentSnapshot doc) {
    return EquipmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'rarity': rarity,
      'tier': tier,
      'requiredLevel': requiredLevel,
      'statModifiers': statModifiers,
      'hpBonus': hpBonus,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}
