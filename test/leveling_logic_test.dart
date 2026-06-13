import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/logic/leveling.dart';

void main() {
  group('expRequiredForLevel', () {
    test('đúng công thức lvl*1000 + lvl*lvl*50', () {
      expect(expRequiredForLevel(1), 1050);
      expect(expRequiredForLevel(2), 2200);
      expect(expRequiredForLevel(3), 3450);
      expect(expRequiredForLevel(5), 6250);
    });

    test('EXP yêu cầu tăng dần theo từng cấp', () {
      for (var lvl = 1; lvl < kMaxLevel; lvl++) {
        expect(
          expRequiredForLevel(lvl + 1) > expRequiredForLevel(lvl),
          isTrue,
        );
      }
    });
  });

  group('applyReward', () {
    test('chưa đủ EXP thì không lên cấp, chỉ cộng EXP và Gold', () {
      final r = applyReward(
        currentLevel: 1,
        currentExp: 0,
        currentStatPoints: 0,
        currentGold: 100,
        expReward: 500,
        goldReward: 50,
      );
      expect(r.level, 1);
      expect(r.exp, 500);
      expect(r.statPoints, 0);
      expect(r.gold, 150);
    });

    test('đủ EXP thì lên đúng 1 cấp, +3 stat point, cộng Gold theo cấp', () {
      final r = applyReward(
        currentLevel: 1,
        currentExp: 0,
        currentStatPoints: 0,
        currentGold: 100,
        expReward: 1050,
        goldReward: 50,
      );
      expect(r.level, 2);
      expect(r.exp, 0);
      expect(r.statPoints, 3);
      expect(r.gold, 650); // 100 + 50 + (2 * 250)
    });

    test('EXP lớn thì lên nhiều cấp trong một lần', () {
      final r = applyReward(
        currentLevel: 1,
        currentExp: 0,
        currentStatPoints: 0,
        currentGold: 0,
        expReward: expRequiredForLevel(1) + expRequiredForLevel(2),
        goldReward: 0,
      );
      expect(r.level, 3);
      expect(r.exp, 0);
      expect(r.statPoints, 6); // +3 +3
      expect(r.gold, 1250); // (2*250) + (3*250)
    });

    test('cấp chia hết cho 10 được thưởng 10 stat point', () {
      final r = applyReward(
        currentLevel: 9,
        currentExp: 0,
        currentStatPoints: 0,
        currentGold: 0,
        expReward: expRequiredForLevel(9),
        goldReward: 0,
      );
      expect(r.level, 10);
      expect(r.statPoints, 10);
    });

    test('không vượt quá cấp tối đa 50 và EXP bị giới hạn', () {
      final r = applyReward(
        currentLevel: 50,
        currentExp: 0,
        currentStatPoints: 0,
        currentGold: 0,
        expReward: 999999,
        goldReward: 0,
      );
      expect(r.level, 50);
      expect(r.exp, lessThanOrEqualTo(expRequiredForLevel(50)));
    });
  });
}
