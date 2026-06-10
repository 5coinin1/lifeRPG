import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String heroId;
  final String equipmentId;
  final int quantity;
  final String source; // shop, guild, boss, trade, starter
  final bool tradable;
  final bool locked;
  final DateTime acquiredAt;

  InventoryItemModel({
    required this.id,
    required this.heroId,
    required this.equipmentId,
    this.quantity = 1,
    this.source = 'starter',
    this.tradable = false,
    this.locked = false,
    DateTime? acquiredAt,
  }) : acquiredAt = acquiredAt ?? DateTime.now();

  factory InventoryItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryItemModel(
      id: docId,
      heroId: map['heroId'] as String? ?? '',
      equipmentId: map['equipmentId'] as String? ?? docId,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      source: map['source'] as String? ?? 'starter',
      tradable: map['tradable'] as bool? ?? false,
      locked: map['locked'] as bool? ?? false,
      acquiredAt: (map['acquiredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory InventoryItemModel.fromDoc(DocumentSnapshot doc) {
    return InventoryItemModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heroId': heroId,
      'equipmentId': equipmentId,
      'quantity': quantity,
      'source': source,
      'tradable': tradable,
      'locked': locked,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
    };
  }
}
