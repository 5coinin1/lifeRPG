import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guild_model.dart';
import '../models/guild_quest_model.dart';
import 'boss_raid_service.dart';

class GuildService {
  final _db = FirebaseFirestore.instance;

  // ── CREATE GUILD ─────────────────────────────────────────────────────────────
  Future<String> createGuild({
    required String ownerId,
    required String name,
    required String description,
    required String iconName,
    required String tag,
  }) async {
    final docRef = _db.collection('guilds').doc();
    final guild = GuildModel(
      id: docRef.id,
      name: name,
      description: description,
      iconName: iconName,
      tag: tag,
      ownerId: ownerId,
      guardianIds: [ownerId],
      heroIds: [],
      createdAt: DateTime.now(),
    );
    await docRef.set(guild.toMap());
    await _db.collection('guardians').doc(ownerId).update({
      'guildId': docRef.id,
    });
    return docRef.id;
  }

  // ── REQUEST TO JOIN ───────────────────────────────────────────────────────────
  Future<void> requestToJoin({
    required String guildId,
    String? guardianId,
    String? heroId,
  }) async {
    final ref = _db.collection('guilds').doc(guildId);
    if (guardianId != null) {
      final guardianDoc = await _db
          .collection('guardians')
          .doc(guardianId)
          .get();
      final currentGuild = guardianDoc.data()?['guildId']?.toString();
      if (currentGuild != null &&
          currentGuild.isNotEmpty &&
          currentGuild != guildId) {
        throw Exception('Guardian is already in another guild.');
      }
      await ref.update({
        'pendingGuardianIds': FieldValue.arrayUnion([guardianId]),
      });
    }
    if (heroId != null) {
      final heroDoc = await _db.collection('heroes').doc(heroId).get();
      final currentGuild = heroDoc.data()?['guildId']?.toString();
      if (currentGuild != null &&
          currentGuild.isNotEmpty &&
          currentGuild != guildId) {
        throw Exception('Hero is already in another guild.');
      }
      await ref.update({
        'pendingHeroIds': FieldValue.arrayUnion([heroId]),
      });
    }
  }

  // ── APPROVE GUARDIAN ─────────────────────────────────────────────────────────
  /// Duyệt guardian + cho chọn hero nào đưa vào guild.
  Future<void> approveGuardian({
    required String guildId,
    required String guardianId,
    required List<String> selectedHeroIds,
  }) async {
    final batch = _db.batch();
    final guildRef = _db.collection('guilds').doc(guildId);

    // Di chuyển guardian từ pending → chính thức
    batch.update(guildRef, {
      'guardianIds': FieldValue.arrayUnion([guardianId]),
      'pendingGuardianIds': FieldValue.arrayRemove([guardianId]),
    });
    batch.update(_db.collection('guardians').doc(guardianId), {
      'guildId': guildId,
    });

    // Thêm các hero được chọn. Không tự kéo toàn bộ con em của guardian.
    for (final hid in selectedHeroIds) {
      final heroDoc = await _db.collection('heroes').doc(hid).get();
      final currentGuild = heroDoc.data()?['guildId']?.toString();
      if (currentGuild != null &&
          currentGuild.isNotEmpty &&
          currentGuild != guildId) {
        throw Exception('Hero $hid is already in another guild.');
      }
      batch.update(guildRef, {
        'heroIds': FieldValue.arrayUnion([hid]),
        'pendingHeroIds': FieldValue.arrayRemove([hid]),
      });
      batch.update(_db.collection('heroes').doc(hid), {'guildId': guildId});
    }
    await batch.commit();
  }

  // ── APPROVE HERO ──────────────────────────────────────────────────────────────
  /// Duyệt hero join → tự kéo guardian của hero vào (nếu guardian chưa có guild).
  Future<void> approveHero({
    required String guildId,
    required String heroId,
  }) async {
    final guildRef = _db.collection('guilds').doc(guildId);
    final heroDoc = await _db.collection('heroes').doc(heroId).get();
    if (!heroDoc.exists) throw Exception('Hero not found.');

    final heroGuild = heroDoc.data()?['guildId']?.toString();
    if (heroGuild != null && heroGuild.isNotEmpty && heroGuild != guildId) {
      throw Exception('Hero is already in another guild.');
    }

    final guardianId = heroDoc.data()?['guardianId'] as String?;
    if (guardianId != null && guardianId.isNotEmpty) {
      final guardianDoc = await _db
          .collection('guardians')
          .doc(guardianId)
          .get();
      final guardianGuild = guardianDoc.data()?['guildId']?.toString();
      if (guardianGuild != null &&
          guardianGuild.isNotEmpty &&
          guardianGuild != guildId) {
        throw Exception('Guardian is already in another guild.');
      }
    }

    final batch = _db.batch();
    batch.update(guildRef, {
      'heroIds': FieldValue.arrayUnion([heroId]),
      'pendingHeroIds': FieldValue.arrayRemove([heroId]),
    });
    batch.update(_db.collection('heroes').doc(heroId), {'guildId': guildId});
    if (guardianId != null && guardianId.isNotEmpty) {
      batch.update(guildRef, {
        'guardianIds': FieldValue.arrayUnion([guardianId]),
      });
      batch.update(_db.collection('guardians').doc(guardianId), {
        'guildId': guildId,
      });
    }
    await batch.commit();
  }

  // ── REJECT REQUEST ────────────────────────────────────────────────────────────
  Future<void> rejectRequest({
    required String guildId,
    required String memberId,
    required bool isGuardian,
  }) async {
    final field = isGuardian ? 'pendingGuardianIds' : 'pendingHeroIds';
    await _db.collection('guilds').doc(guildId).update({
      field: FieldValue.arrayRemove([memberId]),
    });
  }

  // ── PROPOSE QUEST ─────────────────────────────────────────────────────────────
  Future<void> proposeQuest({
    required String guildId,
    required String createdBy,
    required String title,
    required String description,
    String attribute = 'STRENGTH',
    required int targetAmount,
    required String unit,
    required int daysAvailable,
    required List<String> heroIds,
  }) async {
    final docRef = _db.collection('guild_quests').doc();
    final quest = GuildQuestModel(
      id: docRef.id,
      guildId: guildId,
      createdBy: createdBy,
      title: title,
      description: description,
      attribute: attribute,
      targetAmount: targetAmount,
      unit: unit,
      deadline: DateTime.now().add(Duration(days: daysAvailable)),
      createdAt: DateTime.now(),
      expReward: 150, // guild EXP reward
      heroExpReward: 50, // hero EXP reward
      heroGoldReward: 100, // hero gold reward
      upvotes: [],
      isApproved: false,
      assignedHeroIds: [],
      requiredPerHero: 0,
      heroProgress: {},
      heroCompletionApproved: {},
      isRejected: false,
    );
    await docRef.set(quest.toMap());
  }

  // ── VOTE QUEST ────────────────────────────────────────────────────────────────
  /// Vote approve/reject cho quest.
  /// Khi vote ≥ 70% approve → auto approve, snapshot heroIds, chia requiredPerHero.
  Future<void> voteQuest({
    required String guildId,
    required String questId,
    required String guardianId,
    required bool approve,
  }) async {
    final questRef = _db.collection('guild_quests').doc(questId);
    final guildDoc = await _db.collection('guilds').doc(guildId).get();
    final guildData = guildDoc.data();
    if (guildData == null) throw Exception('Guild not found.');

    final guardianIds = <String>{
      ...List<String>.from(guildData['guardianIds'] ?? []),
    };
    final guardiansByProfile = await _db
        .collection('guardians')
        .where('guildId', isEqualTo: guildId)
        .get();
    guardianIds.addAll(guardiansByProfile.docs.map((doc) => doc.id));

    if (!guardianIds.contains(guardianId)) {
      throw Exception('Only guild guardians can vote on guild quests.');
    }

    final existingQuest = await questRef.get();
    final existingData = existingQuest.data();
    if (existingData == null) throw Exception('Quest not found.');
    if (existingData['isApproved'] == true ||
        existingData['isRejected'] == true) {
      return;
    }

    if (approve) {
      await questRef.update({
        'upvotes': FieldValue.arrayUnion([guardianId]),
        'downvotes': FieldValue.arrayRemove([guardianId]),
      });
    } else {
      await questRef.update({
        'upvotes': FieldValue.arrayRemove([guardianId]),
        'downvotes': FieldValue.arrayUnion([guardianId]),
      });
    }

    // Check threshold
    final questDoc = await questRef.get();
    final data = questDoc.data()!;
    final upvotes = List<String>.from(
      data['upvotes'] ?? [],
    ).where(guardianIds.contains).toList();
    final downvotes = List<String>.from(
      data['downvotes'] ?? [],
    ).where(guardianIds.contains).toList();
    if (data['isApproved'] == true || data['isRejected'] == true) return;

    final totalEligibleGuardians = guardianIds.length;
    final percent = totalEligibleGuardians > 0
        ? upvotes.length / totalEligibleGuardians
        : 0.0;
    if (percent > 0.7) {
      await _activateQuest(
        guildId: guildId,
        questId: questId,
        guildData: guildData,
        questData: data,
      );
      return;
    }

    final rejectPercent = totalEligibleGuardians > 0
        ? downvotes.length / totalEligibleGuardians
        : 0.0;
    if (rejectPercent >= 0.3) {
      await questRef.update({
        'isRejected': true,
        'rejectionReason': 'vote',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> ownerApproveQuest({
    required String guildId,
    required String questId,
    required String ownerId,
  }) async {
    final guildDoc = await _db.collection('guilds').doc(guildId).get();
    final guildData = guildDoc.data();
    if (guildData == null) throw Exception('Guild not found.');
    if (guildData['ownerId'] != ownerId) {
      throw Exception('Only the guild owner can approve directly.');
    }

    final questDoc = await _db.collection('guild_quests').doc(questId).get();
    final questData = questDoc.data();
    if (questData == null) throw Exception('Quest not found.');
    if (questData['isApproved'] == true || questData['isRejected'] == true) {
      return;
    }

    await _activateQuest(
      guildId: guildId,
      questId: questId,
      guildData: guildData,
      questData: questData,
    );
  }

  Future<void> ownerRejectQuest({
    required String guildId,
    required String questId,
    required String ownerId,
  }) async {
    final guildDoc = await _db.collection('guilds').doc(guildId).get();
    final guildData = guildDoc.data();
    if (guildData == null) throw Exception('Guild not found.');
    if (guildData['ownerId'] != ownerId) {
      throw Exception('Only the guild owner can reject directly.');
    }

    await _db.collection('guild_quests').doc(questId).update({
      'isRejected': true,
      'rejectionReason': 'admin',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _activateQuest({
    required String guildId,
    required String questId,
    required Map<String, dynamic> guildData,
    required Map<String, dynamic> questData,
  }) async {
    final heroIds = List<String>.from(guildData['heroIds'] ?? []);
    if (heroIds.isEmpty) return;

    final target = (questData['targetAmount'] as int? ?? 0);
    final perHero = heroIds.isNotEmpty ? (target / heroIds.length).ceil() : 0;
    final heroExpReward = (questData['heroExpReward'] as num?)?.toInt() ?? 50;
    final heroGoldReward =
        (questData['heroGoldReward'] as num?)?.toInt() ?? 100;
    await _db.collection('guild_quests').doc(questId).update({
      'isApproved': true,
      'isRejected': false,
      'assignedHeroIds': heroIds,
      'requiredPerHero': perHero,
    });
    await _createGuildTasksForHeroes(
      guildId: guildId,
      guildName: guildData['name'] as String? ?? 'Guild',
      questId: questId,
      title: questData['title'] as String? ?? '',
      description: questData['description'] as String? ?? '',
      expReward: questData['expReward'] as int? ?? 150,
      heroExpReward: heroExpReward,
      heroGoldReward: heroGoldReward,
      targetPerHero: perHero,
      heroIds: heroIds,
    );
  }

  // ── UPDATE HERO PROGRESS ─────────────────────────────────────────────────────
  Future<void> updateHeroProgress({
    required String questId,
    required String heroId,
    required int amount,
  }) async {
    final questRef = _db.collection('guild_quests').doc(questId);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(questRef);
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['isCompleted'] == true) return;
      final deadline = (data['deadline'] as Timestamp?)?.toDate();
      if (deadline != null && DateTime.now().isAfter(deadline)) return;
      final assigned = List<String>.from(data['assignedHeroIds'] ?? []);
      if (!assigned.contains(heroId)) return;
      final required = (data['requiredPerHero'] as num?)?.toInt() ?? 0;
      final progress = Map<String, int>.from(doc.data()?['heroProgress'] ?? {});
      progress[heroId] = ((progress[heroId] ?? 0) + amount).clamp(0, required);
      tx.update(questRef, {'heroProgress': progress});
    });
  }

  // ── APPROVE HERO COMPLETION ──────────────────────────────────────────────────
  Future<void> approveHeroCompletion({
    required String questId,
    required String heroId,
    String? guardianId,
  }) async {
    if (guardianId != null) {
      final heroDoc = await _db.collection('heroes').doc(heroId).get();
      if (heroDoc.data()?['guardianId'] != guardianId) {
        throw Exception(
          'Only the hero guardian can approve this contribution.',
        );
      }
    }
    final questRef = _db.collection('guild_quests').doc(questId);
    return _db.runTransaction((tx) async {
      final doc = await tx.get(questRef);
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null || data['isCompleted'] == true) return;

      final progress = Map<String, int>.from(data['heroProgress'] ?? {});
      final required = (data['requiredPerHero'] as num?)?.toInt() ?? 0;
      if ((progress[heroId] ?? 0) < required) return;

      final approvals = Map<String, bool>.from(
        doc.data()?['heroCompletionApproved'] ?? {},
      );
      approvals[heroId] = true;
      tx.update(questRef, {'heroCompletionApproved': approvals});
      final guildId = data['guildId'] as String? ?? '';
      final questTitle = data['title'] as String? ?? '';
      final attribute = data['attribute'] as String? ?? 'STRENGTH';
      if (guildId.isNotEmpty && questTitle.isNotEmpty) {
        final skillRef = _db
            .collection('hero_raid_skills')
            .doc(heroId)
            .collection('skills')
            .doc(questId);
        tx.set(
          skillRef,
          BossRaidService.questSkillData(
            heroId: heroId,
            guildId: guildId,
            questId: questId,
            questTitle: questTitle,
            attribute: attribute,
          ),
          SetOptions(merge: true),
        );
      }

      // Nếu ≥ 50% heroes hoàn thành → mark quest complete
      final assigned = List<String>.from(doc.data()?['assignedHeroIds'] ?? []);
      final approvedCount = approvals.values.where((v) => v).length;
      if (assigned.isNotEmpty && (approvedCount / assigned.length) > 0.5) {
        final deadline = (doc.data()?['deadline'] as Timestamp?)?.toDate();
        final now = DateTime.now();
        if (deadline != null && now.isAfter(deadline)) {
          final expReward = (data['expReward'] as num?)?.toInt() ?? 0;
          DocumentReference<Map<String, dynamic>>? guildRef;
          DocumentSnapshot<Map<String, dynamic>>? guildDoc;
          if (guildId.isNotEmpty) {
            guildRef = _db.collection('guilds').doc(guildId);
            guildDoc = await tx.get(guildRef);
          }

          tx.update(questRef, {
            'isCompleted': true,
            'completedAt': Timestamp.fromDate(now),
          });
          if (guildRef != null && guildDoc != null && guildDoc.exists) {
            final currentLevel =
                (guildDoc.data()?['level'] as num?)?.toInt() ?? 1;
            final currentExp = (guildDoc.data()?['exp'] as num?)?.toInt() ?? 0;
            final leveled = _applyGuildExp(currentLevel, currentExp, expReward);
            tx.update(guildRef, {'level': leveled.level, 'exp': leveled.exp});
          }
        }
      }
    });
  }

  ({int level, int exp}) _applyGuildExp(int level, int exp, int gainedExp) {
    var nextLevel = level;
    var nextExp = exp + gainedExp;
    int requiredForLevel(int lvl) => (lvl * 2000) + (lvl * lvl * 100);

    while (nextLevel < 50 && nextExp >= requiredForLevel(nextLevel)) {
      nextExp -= requiredForLevel(nextLevel);
      nextLevel++;
    }

    return (level: nextLevel, exp: nextExp);
  }

  Future<void> _createGuildTasksForHeroes({
    required String guildId,
    required String guildName,
    required String questId,
    required String title,
    required String description,
    required int expReward,
    required int heroExpReward,
    required int heroGoldReward,
    required int targetPerHero,
    required List<String> heroIds,
  }) async {
    final batch = _db.batch();
    for (final heroId in heroIds) {
      final heroDoc = await _db.collection('heroes').doc(heroId).get();
      final guardianId = heroDoc.data()?['guardianId'] as String? ?? '';
      final taskRef = _db.collection('tasks').doc();
      batch.set(taskRef, {
        'id': taskRef.id,
        'guardianId': guardianId,
        'heroId': heroId,
        'title': title,
        'description': '$description\nGuild: $guildName',
        'expReward': heroExpReward,
        'goldReward': heroGoldReward,
        'targetCount': targetPerHero,
        'currentProgress': 0,
        'status': 'todo',
        'difficulty': 'HARD',
        'noteFromParent': null,
        'source': 'guild',
        'guildId': guildId,
        'guildQuestId': questId,
        'guildName': guildName,
        'guildApprovedProgress': 0,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }
}
