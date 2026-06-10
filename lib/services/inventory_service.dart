import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment_model.dart';
import '../models/hero_model.dart';
import '../models/inventory_item_model.dart';

class InventoryEntry {
  final InventoryItemModel inventoryItem;
  final EquipmentModel equipment;

  const InventoryEntry({required this.inventoryItem, required this.equipment});
}

class InventoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _items(String heroId) =>
      _db.collection('hero_inventories').doc(heroId).collection('items');

  static String starterEquipmentIdForPath(String characterPath) {
    switch (characterPath) {
      case 'INT':
        return 'w_int_0';
      case 'SPI':
        return 'w_spi_0';
      case 'AGI':
        return 'w_agi_0';
      case 'STR':
      default:
        return 'w_str_0';
    }
  }

  static Future<void> ensureStarterInventory(HeroModel hero) async {
    final starterIds = [
      starterEquipmentIdForPath(hero.characterPath),
      'a_common_0',
    ];

    for (final equipmentId in starterIds) {
      final existing = await _items(hero.uid).doc(equipmentId).get();
      if (existing.exists) continue;

      await grantItem(
        heroId: hero.uid,
        equipmentId: equipmentId,
        source: 'starter',
        tradable: false,
      );
    }
  }

  static Future<void> grantItem({
    required String heroId,
    required String equipmentId,
    String source = 'shop',
    bool tradable = true,
    bool locked = false,
    int quantity = 1,
  }) async {
    final ref = _items(heroId).doc(equipmentId);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (snapshot.exists) {
        final current = (snapshot.data()?['quantity'] as num?)?.toInt() ?? 1;
        tx.update(ref, {
          'quantity': current + quantity,
          'source': source,
          'tradable': tradable,
          'locked': locked,
        });
      } else {
        tx.set(
          ref,
          InventoryItemModel(
            id: equipmentId,
            heroId: heroId,
            equipmentId: equipmentId,
            quantity: quantity,
            source: source,
            tradable: tradable,
            locked: locked,
          ).toMap(),
        );
      }
    });
  }

  static Stream<List<InventoryEntry>> inventoryEntriesStream(String heroId) {
    return _items(heroId).snapshots().asyncMap((snapshot) async {
      final entries = <InventoryEntry>[];
      for (final doc in snapshot.docs) {
        final item = InventoryItemModel.fromDoc(doc);
        final equipmentDoc = await _db
            .collection('equipments')
            .doc(item.equipmentId)
            .get();
        if (!equipmentDoc.exists) continue;
        entries.add(
          InventoryEntry(
            inventoryItem: item,
            equipment: EquipmentModel.fromDoc(equipmentDoc),
          ),
        );
      }
      entries.sort(
        (a, b) =>
            a.equipment.requiredLevel.compareTo(b.equipment.requiredLevel),
      );
      return entries;
    });
  }

  static Future<void> equipItem({
    required String heroId,
    required InventoryEntry entry,
  }) async {
    final ownedDoc = await _items(heroId).doc(entry.inventoryItem.id).get();
    if (!ownedDoc.exists) {
      throw Exception('Hero does not own this item.');
    }
    if (entry.inventoryItem.locked) {
      throw Exception('This item is locked.');
    }

    final field = switch (entry.equipment.type) {
      'ARMOR' => 'equippedArmorId',
      'PET' => 'equippedPetId',
      _ => 'equippedWeaponId',
    };
    await _db.collection('heroes').doc(heroId).update({
      field: entry.equipment.id,
    });
  }

  static Future<void> unequipItem({
    required String heroId,
    required InventoryEntry entry,
  }) async {
    final field = switch (entry.equipment.type) {
      'ARMOR' => 'equippedArmorId',
      'PET' => 'equippedPetId',
      _ => 'equippedWeaponId',
    };
    await _db.collection('heroes').doc(heroId).update({
      field: '',
    });
  }
}
