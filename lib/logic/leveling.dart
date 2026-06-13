/// Logic tính EXP và lên cấp cho Hero của ứng dụng Life RPG.
///
/// Phần tính toán thuần (không phụ thuộc Firebase) được tách riêng ra đây để
/// có thể kiểm thử bằng unit test. Công thức khớp với logic trong
/// `TaskService.approveTask` và dữ liệu khởi tạo của GameSeed.

/// Số EXP cần để vượt qua cấp [lvl] (lên cấp kế tiếp).
int expRequiredForLevel(int lvl) => (lvl * 1000) + (lvl * lvl * 50);

/// Cấp độ tối đa của Hero.
const int kMaxLevel = 50;

/// Trạng thái tiến độ của Hero sau khi nhận thưởng.
class LevelProgress {
  final int level;
  final int exp;
  final int statPoints;
  final int gold;

  const LevelProgress({
    required this.level,
    required this.exp,
    required this.statPoints,
    required this.gold,
  });
}

/// Cộng phần thưởng [expReward] và [goldReward] vào trạng thái hiện tại của Hero,
/// xử lý lên cấp (có thể lên nhiều cấp), cộng điểm chỉ số và Gold theo cấp mới,
/// đồng thời chặn không vượt quá [kMaxLevel].
LevelProgress applyReward({
  required int currentLevel,
  required int currentExp,
  required int currentStatPoints,
  required int currentGold,
  required int expReward,
  required int goldReward,
}) {
  int totalExp = currentExp + expReward;
  int newLevel = currentLevel;
  int newStatPoints = currentStatPoints;
  int newGold = currentGold + goldReward;

  while (newLevel < kMaxLevel && totalExp >= expRequiredForLevel(newLevel)) {
    totalExp -= expRequiredForLevel(newLevel);
    newLevel++;
    newStatPoints += (newLevel % 10 == 0) ? 10 : 3;
    newGold += newLevel * 250;
  }

  if (newLevel >= kMaxLevel) {
    newLevel = kMaxLevel;
    final maxExp = expRequiredForLevel(kMaxLevel);
    if (totalExp > maxExp) totalExp = maxExp;
  }

  return LevelProgress(
    level: newLevel,
    exp: totalExp,
    statPoints: newStatPoints,
    gold: newGold,
  );
}
