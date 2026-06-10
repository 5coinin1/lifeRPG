import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';
import '../models/level_model.dart';

class GameDataService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- LEVELS ---
  static Future<LevelModel?> getLevelData(int level) async {
    final doc = await _db.collection('levels').doc(level.toString()).get();
    if (doc.exists) {
      return LevelModel.fromDoc(doc);
    }
    return null;
  }

  static Stream<List<LevelModel>> getAllLevels() {
    return _db.collection('levels')
      .orderBy('level')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => LevelModel.fromDoc(doc)).toList());
  }

  // --- EQUIPMENTS ---
  static Future<EquipmentModel?> getEquipment(String id) async {
    final doc = await _db.collection('equipments').doc(id).get();
    if (doc.exists) {
      return EquipmentModel.fromDoc(doc);
    }
    return null;
  }

  static Stream<List<EquipmentModel>> getEquipmentsByType(String type) {
    return _db.collection('equipments')
      .where('type', isEqualTo: type)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => EquipmentModel.fromDoc(doc)).toList());
  }

  static Future<List<EquipmentModel>> fetchAllEquipments() async {
    final snapshot = await _db.collection('equipments').get();
    return snapshot.docs.map((doc) => EquipmentModel.fromDoc(doc)).toList();
  }
}
