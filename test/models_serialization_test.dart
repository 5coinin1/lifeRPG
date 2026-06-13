import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/models/account_model.dart';
import 'package:flutter_application/models/task_model.dart';
import 'package:flutter_application/models/equipment_model.dart';
import 'package:flutter_application/models/inventory_item_model.dart';
import 'package:flutter_application/models/hero_model.dart';
import 'package:flutter_application/models/level_model.dart';

void main() {
  group('LevelModel - công thức chỉ số theo cấp', () {
    test('maxHp / maxMana / maxStamina tính đúng theo cấp', () {
      expect(LevelModel.maxHpForLevel(1), 100);
      expect(LevelModel.maxHpForLevel(5), 180); // 100 + 4*20
      expect(LevelModel.maxManaForLevel(5), 140); // 100 + 4*10
      expect(LevelModel.maxStaminaForLevel(5), 132); // 100 + 4*8
    });
  });

  group('AccountModel - ORM round-trip', () {
    test('toMap/fromMap giữ nguyên dữ liệu và vai trò', () {
      final acc = AccountModel(
        uid: 'u1',
        email: 'a@b.com',
        displayName: 'Tester',
        role: UserRole.guardian,
        createdAt: DateTime(2026, 1, 1),
      );
      final back = AccountModel.fromMap(acc.toMap());
      expect(back.uid, 'u1');
      expect(back.email, 'a@b.com');
      expect(back.role, UserRole.guardian);
      expect(back.isGuardian, isTrue);
      expect(back.isHero, isFalse);
    });

    test('vai trò mặc định là hero khi dữ liệu không phải guardian', () {
      final acc = AccountModel.fromMap(
        {'uid': 'x', 'email': '', 'displayName': ''},
      );
      expect(acc.role, UserRole.hero);
    });
  });

  group('TaskModel - ORM round-trip', () {
    test('toMap/fromMap giữ nguyên các trường chính', () {
      final t = TaskModel(
        id: 't1',
        guardianId: 'g1',
        heroId: 'h1',
        title: 'Dọn phòng',
        description: 'Dọn sạch phòng ngủ',
        expReward: 100,
        goldReward: 50,
        targetCount: 3,
        difficulty: 'MEDIUM',
      );
      final back = TaskModel.fromMap(t.toMap(), t.id);
      expect(back.id, 't1');
      expect(back.title, 'Dọn phòng');
      expect(back.expReward, 100);
      expect(back.goldReward, 50);
      expect(back.targetCount, 3);
      expect(back.difficulty, 'MEDIUM');
      expect(back.status, 'todo');
    });
  });

  group('EquipmentModel - ORM round-trip', () {
    test('giữ nguyên statModifiers và các thuộc tính', () {
      final e = EquipmentModel(
        id: 'w_str_1',
        name: 'Sword',
        type: 'WEAPON',
        rarity: 'RARE',
        tier: 1,
        requiredLevel: 5,
        statModifiers: {'STR': 10, 'AGI': -2},
        hpBonus: 20,
        imageUrl: 'http://x',
        description: 'A sword',
      );
      final back = EquipmentModel.fromMap(e.toMap(), e.id);
      expect(back.id, 'w_str_1');
      expect(back.type, 'WEAPON');
      expect(back.statModifiers['STR'], 10);
      expect(back.statModifiers['AGI'], -2);
      expect(back.hpBonus, 20);
      expect(back.requiredLevel, 5);
    });
  });

  group('InventoryItemModel - ORM round-trip', () {
    test('giữ nguyên số lượng, nguồn gốc và cờ trạng thái', () {
      final inv = InventoryItemModel(
        id: 'i1',
        heroId: 'h1',
        equipmentId: 'w_str_1',
        quantity: 2,
        source: 'shop',
        tradable: true,
      );
      final back = InventoryItemModel.fromMap(inv.toMap(), inv.id);
      expect(back.equipmentId, 'w_str_1');
      expect(back.quantity, 2);
      expect(back.source, 'shop');
      expect(back.tradable, isTrue);
      expect(back.locked, isFalse);
    });
  });

  group('HeroModel.fromMap - giá trị mặc định & dữ liệu lồng nhau', () {
    test('thiếu maxHp thì suy ra từ level', () {
      final hero = HeroModel.fromMap({
        'uid': 'h1',
        'displayName': 'Hero',
        'email': 'h@b.com',
        'characterPath': 'STR',
        'level': 5,
      });
      expect(hero.level, 5);
      expect(hero.maxHp, LevelModel.maxHpForLevel(5)); // 180
      expect(hero.strength, 10); // mặc định
      expect(hero.gold, 100); // mặc định
    });

    test('đọc được attributes lồng nhau (str/agi/int/spi)', () {
      final hero = HeroModel.fromMap({
        'uid': 'h2',
        'displayName': 'Hero2',
        'email': '',
        'characterPath': 'INT',
        'attributes': {'str': 15, 'agi': 12, 'int': 20, 'spi': 8},
      });
      expect(hero.strength, 15);
      expect(hero.agility, 12);
      expect(hero.intellect, 20);
      expect(hero.spirit, 8);
    });
  });
}
