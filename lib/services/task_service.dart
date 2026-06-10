import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/level_model.dart';
import 'guild_service.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- GUARDIAN: CREATE TASKS ---

  /// Phụ huynh tạo nhiệm vụ cho 1 con em cụ thể
  static Future<void> createTaskForHero({
    required String guardianId,
    required String heroId,
    required String title,
    required String description,
    required int expReward,
    required int goldReward,
    int targetCount = 1,
    String difficulty = 'EASY',
  }) async {
    final docRef = _firestore.collection('tasks').doc();
    final task = TaskModel(
      id: docRef.id,
      guardianId: guardianId,
      heroId: heroId,
      title: title,
      description: description,
      expReward: expReward,
      goldReward: goldReward,
      targetCount: targetCount,
      difficulty: difficulty,
    );
    await docRef.set(task.toMap());
  }

  /// Phụ huynh tạo nhiệm vụ cho toàn bộ con em trong family
  static Future<void> createTaskForAllHeroes({
    required String guardianId,
    required String title,
    required String description,
    required int expReward,
    required int goldReward,
    int targetCount = 1,
    String difficulty = 'EASY',
  }) async {
    // 1. Lấy danh sách hero thuộc guardian này
    final query = await _firestore
        .collection('heroes')
        .where('guardianId', isEqualTo: guardianId)
        .get();

    // 2. Tạo task cho từng hero bằng batch write
    final batch = _firestore.batch();
    for (var doc in query.docs) {
      final docRef = _firestore.collection('tasks').doc();
      final task = TaskModel(
        id: docRef.id,
        guardianId: guardianId,
        heroId: doc.id,
        title: title,
        description: description,
        expReward: expReward,
        goldReward: goldReward,
        targetCount: targetCount,
        difficulty: difficulty,
      );
      batch.set(docRef, task.toMap());
    }
    await batch.commit();
  }

  // --- HERO: VIEW AND UPDATE TASKS ---

  /// Lấy danh sách nhiệm vụ của 1 hero
  static Stream<List<TaskModel>> getTasksForHero(String heroId) {
    return _firestore
        .collection('tasks')
        .where('heroId', isEqualTo: heroId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .toList();
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  /// Con em cập nhật tiến độ (Tăng 1 phần)
  static Future<void> incrementTaskProgress(TaskModel task) async {
    if (task.status != 'todo') return; // Chỉ tăng khi đang làm

    int newProgress = task.currentProgress + 1;
    String newStatus = 'todo';

    // Nếu đạt chỉ tiêu thì chuyển sang chờ duyệt
    if (newProgress >= task.targetCount) {
      newProgress = task.targetCount;
      newStatus = 'pending_approval';
    }

    await _firestore.collection('tasks').doc(task.id).update({
      'currentProgress': newProgress,
      'status': newStatus,
    });
  }

  /// Con em bấm hoàn thành (Gửi duyệt ngay lập tức dù chưa đủ tiến độ)
  static Future<void> submitTaskForApproval(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': 'pending_approval',
    });
  }

  // --- GUARDIAN: VIEW AND CONFIRM TASKS ---

  /// Lấy danh sách các nhiệm vụ đang chờ duyệt hoặc đang thực hiện của tất cả con em
  static Stream<List<TaskModel>> getPendingTasksForGuardian(String guardianId) {
    return _firestore
        .collection('tasks')
        .where('guardianId', isEqualTo: guardianId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
              .where(
                (task) =>
                    task.status == 'todo' || task.status == 'pending_approval',
              )
              .toList();
          tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return tasks;
        });
  }

  /// Phụ huynh xác nhận hoàn thành và trả thưởng
  static Future<void> approveTask(TaskModel task, String note) async {
    if (task.source == 'guild' && task.guildQuestId != null) {
      await _approveGuildTaskProgress(task, note);
      return;
    }

    final taskRef = _firestore.collection('tasks').doc(task.id);
    final heroRef = _firestore.collection('heroes').doc(task.heroId);

    await _firestore.runTransaction((transaction) async {
      final heroSnapshot = await transaction.get(heroRef);
      if (!heroSnapshot.exists) return; // Bỏ qua nếu hero không tồn tại

      // 1. Cập nhật task
      transaction.update(taskRef, {
        'status': 'completed',
        'noteFromParent': note,
      });

      // 2. Lấy chỉ số hiện tại
      int currentExp = (heroSnapshot.data()?['exp'] as num?)?.toInt() ?? 0;
      int currentLevel = (heroSnapshot.data()?['level'] as num?)?.toInt() ?? 1;
      int currentGold = (heroSnapshot.data()?['gold'] as num?)?.toInt() ?? 0;
      int currentStatPoints =
          (heroSnapshot.data()?['statPoints'] as num?)?.toInt() ?? 0;

      // Cộng dồn thưởng từ task
      int totalExp = currentExp + task.expReward;
      int newLevel = currentLevel;
      int newStatPoints = currentStatPoints;
      int newGold = currentGold + task.goldReward;

      // Công thức EXP yêu cầu (Khớp với GameSeed)
      int expRequiredForLevel(int lvl) => (lvl * 1000) + (lvl * lvl * 50);

      // 3. Vòng lặp level up nếu EXP vượt mốc yêu cầu
      while (newLevel < 50 && totalExp >= expRequiredForLevel(newLevel)) {
        totalExp -= expRequiredForLevel(
          newLevel,
        ); // Trừ đi lượng exp đã dùng để lên cấp
        newLevel++; // Tăng cấp

        // Thưởng khi lên cấp (Khớp với GameSeed)
        newStatPoints += (newLevel % 10 == 0) ? 10 : 3;
        newGold += newLevel * 250;
      }

      // Xử lý MAX LEVEL (Cấp độ 50 là tối đa)
      if (newLevel >= 50) {
        newLevel = 50;
        int maxExp = expRequiredForLevel(50);
        if (totalExp > maxExp) {
          totalExp = maxExp; // Giữ lại exp nhưng không vượt quá cap
        }
      }

      // 4. Lưu vào Firestore
      final updates = <String, dynamic>{
        'level': newLevel,
        'exp': totalExp,
        'gold': newGold,
        'statPoints': newStatPoints,
      };

      // Khi lên cấp: tăng chỉ số tối đa theo level mới và hồi đầy HP/MP/SP
      if (newLevel > currentLevel) {
        updates['maxHp'] = LevelModel.maxHpForLevel(newLevel);
        updates['maxMana'] = LevelModel.maxManaForLevel(newLevel);
        updates['maxStamina'] = LevelModel.maxStaminaForLevel(newLevel);
        updates['hp'] = LevelModel.maxHpForLevel(newLevel);
        updates['mana'] = LevelModel.maxManaForLevel(newLevel);
        updates['stamina'] = LevelModel.maxStaminaForLevel(newLevel);
      }

      transaction.update(heroRef, updates);
    });
  }

  static Future<void> _approveGuildTaskProgress(
    TaskModel task,
    String note,
  ) async {
    final approvedProgress = task.currentProgress.clamp(0, task.targetCount);
    final previousApproved = task.guildApprovedProgress.clamp(
      0,
      task.targetCount,
    );
    final delta = approvedProgress - previousApproved;
    final isComplete = approvedProgress >= task.targetCount;

    if (delta > 0) {
      await GuildService().updateHeroProgress(
        questId: task.guildQuestId!,
        heroId: task.heroId,
        amount: delta,
      );
    }

    if (!isComplete) {
      await _firestore.collection('tasks').doc(task.id).update({
        'status': 'todo',
        'noteFromParent': note,
        'guildApprovedProgress': approvedProgress,
      });
      return;
    }

    await GuildService().approveHeroCompletion(
      questId: task.guildQuestId!,
      heroId: task.heroId,
      guardianId: task.guardianId,
    );

    final taskRef = _firestore.collection('tasks').doc(task.id);
    final heroRef = _firestore.collection('heroes').doc(task.heroId);

    await _firestore.runTransaction((transaction) async {
      final heroSnapshot = await transaction.get(heroRef);
      if (!heroSnapshot.exists) return;

      transaction.update(taskRef, {
        'status': 'completed',
        'noteFromParent': note,
        'guildApprovedProgress': approvedProgress,
      });

      int currentExp = (heroSnapshot.data()?['exp'] as num?)?.toInt() ?? 0;
      int currentLevel = (heroSnapshot.data()?['level'] as num?)?.toInt() ?? 1;
      int currentGold = (heroSnapshot.data()?['gold'] as num?)?.toInt() ?? 0;
      int currentStatPoints =
          (heroSnapshot.data()?['statPoints'] as num?)?.toInt() ?? 0;

      int totalExp = currentExp + task.expReward;
      int newLevel = currentLevel;
      int newStatPoints = currentStatPoints;
      int newGold = currentGold + task.goldReward;

      int expRequiredForLevel(int lvl) => (lvl * 1000) + (lvl * lvl * 50);

      while (newLevel < 50 && totalExp >= expRequiredForLevel(newLevel)) {
        totalExp -= expRequiredForLevel(newLevel);
        newLevel++;
        newStatPoints += (newLevel % 10 == 0) ? 10 : 3;
        newGold += newLevel * 250;
      }

      if (newLevel >= 50) {
        newLevel = 50;
        int maxExp = expRequiredForLevel(50);
        if (totalExp > maxExp) {
          totalExp = maxExp;
        }
      }

      final updates = <String, dynamic>{
        'level': newLevel,
        'exp': totalExp,
        'gold': newGold,
        'statPoints': newStatPoints,
      };

      // Khi lên cấp: tăng chỉ số tối đa theo level mới và hồi đầy HP/MP/SP
      if (newLevel > currentLevel) {
        updates['maxHp'] = LevelModel.maxHpForLevel(newLevel);
        updates['maxMana'] = LevelModel.maxManaForLevel(newLevel);
        updates['maxStamina'] = LevelModel.maxStaminaForLevel(newLevel);
        updates['hp'] = LevelModel.maxHpForLevel(newLevel);
        updates['mana'] = LevelModel.maxManaForLevel(newLevel);
        updates['stamina'] = LevelModel.maxStaminaForLevel(newLevel);
      }

      transaction.update(heroRef, updates);
    });
  }

  /// Phụ huynh từ chối (báo fail / chưa hoàn thành)
  static Future<void> rejectTask(TaskModel task, String reason) async {
    await _firestore.collection('tasks').doc(task.id).update({
      'status': 'failed', // hoặc 'todo' nếu cho phép làm lại
      'noteFromParent': reason,
    });
  }
}
