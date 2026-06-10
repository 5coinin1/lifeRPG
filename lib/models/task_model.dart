import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String guardianId;
  final String heroId;
  final String title;
  final String description;
  final int expReward;
  final int goldReward;
  final int targetCount;
  final int currentProgress;
  final String status; // 'todo', 'pending_approval', 'completed', 'failed'
  final String difficulty; // 'EASY', 'MEDIUM', 'HARD'
  final String? noteFromParent;
  final String? source; // 'guardian' or 'guild'
  final String? guildId;
  final String? guildQuestId;
  final String? guildName;
  final int guildApprovedProgress;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.guardianId,
    required this.heroId,
    required this.title,
    required this.description,
    required this.expReward,
    required this.goldReward,
    this.targetCount = 1,
    this.currentProgress = 0,
    this.status = 'todo',
    this.difficulty = 'EASY',
    this.noteFromParent,
    this.source,
    this.guildId,
    this.guildQuestId,
    this.guildName,
    this.guildApprovedProgress = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guardianId': guardianId,
      'heroId': heroId,
      'title': title,
      'description': description,
      'expReward': expReward,
      'goldReward': goldReward,
      'targetCount': targetCount,
      'currentProgress': currentProgress,
      'status': status,
      'difficulty': difficulty,
      'noteFromParent': noteFromParent,
      'source': source,
      'guildId': guildId,
      'guildQuestId': guildQuestId,
      'guildName': guildName,
      'guildApprovedProgress': guildApprovedProgress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TaskModel(
      id: documentId,
      guardianId: map['guardianId'] ?? '',
      heroId: map['heroId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      expReward: map['expReward']?.toInt() ?? 0,
      goldReward: map['goldReward']?.toInt() ?? 0,
      targetCount: map['targetCount']?.toInt() ?? 1,
      currentProgress: map['currentProgress']?.toInt() ?? 0,
      status: map['status'] ?? 'todo',
      difficulty:
          map['difficulty'] ?? _difficultyFromTarget(map['targetCount']),
      noteFromParent: map['noteFromParent'],
      source: map['source'] as String?,
      guildId: map['guildId'] as String?,
      guildQuestId: map['guildQuestId'] as String?,
      guildName: map['guildName'] as String?,
      guildApprovedProgress: map['guildApprovedProgress']?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  TaskModel copyWith({
    String? id,
    String? guardianId,
    String? heroId,
    String? title,
    String? description,
    int? expReward,
    int? goldReward,
    int? targetCount,
    int? currentProgress,
    String? status,
    String? difficulty,
    String? noteFromParent,
    String? source,
    String? guildId,
    String? guildQuestId,
    String? guildName,
    int? guildApprovedProgress,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      guardianId: guardianId ?? this.guardianId,
      heroId: heroId ?? this.heroId,
      title: title ?? this.title,
      description: description ?? this.description,
      expReward: expReward ?? this.expReward,
      goldReward: goldReward ?? this.goldReward,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      noteFromParent: noteFromParent ?? this.noteFromParent,
      source: source ?? this.source,
      guildId: guildId ?? this.guildId,
      guildQuestId: guildQuestId ?? this.guildQuestId,
      guildName: guildName ?? this.guildName,
      guildApprovedProgress:
          guildApprovedProgress ?? this.guildApprovedProgress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _difficultyFromTarget(dynamic targetCount) {
    final target = (targetCount as num?)?.toInt() ?? 1;
    if (target >= 3) return 'HARD';
    if (target == 2) return 'MEDIUM';
    return 'EASY';
  }
}
