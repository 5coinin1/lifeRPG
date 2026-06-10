// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'game_seed.dart';
import 'user_seed.dart';
import 'guild_seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Đang seed dữ liệu lên Firebase... Xem Terminal/Console.'),
      ),
    ),
  ));

  // Chạy lần lượt theo thứ tự phụ thuộc:
  // 1. Game meta (levels, equipment)
  print('\n==============================');
  print('[1/3] Seed Game Meta Data...');
  print('==============================');
  await GameSeed.seedToFirestore();

  // 2. Users (guardians + heroes) — phải có trước khi guild tham chiếu đến
  print('\n==============================');
  print('[2/3] Seed Users (Guardians + Heroes)...');
  print('==============================');
  await UserSeed.seedUsersToFirestore();

  // 3. Guilds + Guild Quests — tham chiếu đến guardianIds/heroIds đã tồn tại
  print('\n==============================');
  print('[3/3] Seed Guilds + Guild Quests...');
  print('==============================');
  await GuildSeed.seedGuildsToFirestore();

  print('\n🎉 ALL SEED COMPLETED SUCCESSFULLY!');
}
