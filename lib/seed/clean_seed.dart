// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// Script xóa dữ liệu seed cũ:
/// - guardians: parent_3, parent_4, parent_5
/// - heroes: hero_1 -> hero_7
/// - accounts: các doc alias và doc theo Firebase Auth UID có email demo
/// - guilds/guild_quests/tasks demo phụ thuộc vào các user trên
///
/// Lưu ý: script này chỉ dọn Firestore. Firebase Auth users không bị xóa vì
/// client SDK không có quyền admin để xóa tài khoản theo email.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Dang xoa du lieu seed cu... Xem Terminal/Console.'),
        ),
      ),
    ),
  );

  await _cleanOldSeedData();
}

Future<void> _cleanOldSeedData() async {
  final db = FirebaseFirestore.instance;
  final deletedPaths = <String>{};

  const guardianIds = ['parent_3', 'parent_4', 'parent_5'];
  const heroIds = [
    'hero_1',
    'hero_2',
    'hero_3',
    'hero_4',
    'hero_5',
    'hero_6',
    'hero_7',
  ];
  const demoEmails = [
    'lyra@realm.com',
    'thane@realm.com',
    'vesper@realm.com',
    'aran@realm.com',
    'sela@realm.com',
    'dorin@realm.com',
    'mira@realm.com',
    'calder@realm.com',
    'nyx@realm.com',
    'ember@realm.com',
  ];
  const guildIds = ['guild_1', 'guild_2', 'guild_3'];
  const questIds = [
    'quest_1',
    'quest_2',
    'quest_3',
    'quest_4',
    'quest_5',
    'quest_6',
    'quest_7',
  ];

  print('\nBat dau xoa du lieu seed cu...\n');

  Future<void> deleteDoc(DocumentReference<Map<String, dynamic>> doc) async {
    if (!deletedPaths.add(doc.path)) return;

    final snapshot = await doc.get();
    if (!snapshot.exists) {
      print('  - ${doc.path} not found');
      return;
    }

    await doc.delete();
    print('  - ${doc.path} deleted');
  }

  Future<void> deleteByIds(String collection, List<String> ids) async {
    print('\nXoa $collection theo ID...');
    for (final id in ids) {
      await deleteDoc(db.collection(collection).doc(id));
    }
  }

  Future<void> deleteByEmails(String collection) async {
    print('\nXoa $collection theo email demo...');
    for (final email in demoEmails) {
      final snapshot = await db
          .collection(collection)
          .where('email', isEqualTo: email)
          .get();
      for (final doc in snapshot.docs) {
        await deleteDoc(doc.reference);
      }
    }
  }

  Future<void> deleteTasksByField(String field, List<String> values) async {
    print('\nXoa tasks theo $field...');
    for (final value in values) {
      final snapshot = await db
          .collection('tasks')
          .where(field, isEqualTo: value)
          .get();
      for (final doc in snapshot.docs) {
        await deleteDoc(doc.reference);
      }
    }
  }

  await deleteByIds('guardians', guardianIds);
  await deleteByIds('heroes', heroIds);
  await deleteByIds('accounts', [...guardianIds, ...heroIds]);

  await deleteByEmails('guardians');
  await deleteByEmails('heroes');
  await deleteByEmails('accounts');

  await deleteByIds('guilds', guildIds);
  await deleteByIds('guild_quests', questIds);

  await deleteTasksByField('heroId', heroIds);
  await deleteTasksByField('guardianId', guardianIds);

  print('\nXoa guild tasks theo source=guild...');
  final guildTasks = await db
      .collection('tasks')
      .where('source', isEqualTo: 'guild')
      .get();
  for (final doc in guildTasks.docs) {
    await deleteDoc(doc.reference);
  }

  print('\nHoan tat. Da don Firestore seed demo parent_3..5 va hero_1..7.');
}
