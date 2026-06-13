import 'package:cloud_firestore/cloud_firestore.dart';

class GuildQuestModel {
  final String id;
  final String guildId;
  final String createdBy; // UID of the Guardian who proposed the quest
  final String title;
  final String description;
  final String attribute; // 'STRENGTH', 'INTELLECT', 'SPIRIT', 'AGILITY'
  final int targetAmount; // Total amount required for the guild
  final String unit; // e.g., "pushups", "pages"
  final DateTime deadline;
  final DateTime voteDeadline; // Hạn chót để các guardian bỏ phiếu
  final DateTime createdAt;
  final int expReward; // Guild EXP reward (default 150)
  final int heroExpReward; // Hero EXP reward (default 50)
  final int heroGoldReward; // Hero gold reward (default 100)

  // Voting
  final List<String> upvotes; // List of guardianIds who voted YES
  final List<String> downvotes; // List of guardianIds who voted NO
  final bool isApproved; // Becomes true if upvotes > 70% of guild guardians
  final bool isRejected;
  final String? rejectionReason;
  final DateTime? rejectedAt;

  // Execution (populated when approved)
  final List<String>
  assignedHeroIds; // Heroes who were in the guild when approved
  final int requiredPerHero; // targetAmount / assignedHeroIds.length

  // Progress tracking
  // Key: heroId, Value: progress amount
  final Map<String, int> heroProgress;

  // Approval tracking (Parent must approve the hero's contribution)
  // Key: heroId, Value: boolean true if approved
  final Map<String, bool> heroCompletionApproved;

  final bool isCompleted; // True when deadline is reached or total progress met
  final DateTime? completedAt;

  GuildQuestModel({
    required this.id,
    required this.guildId,
    required this.createdBy,
    required this.title,
    required this.description,
    this.attribute = 'STRENGTH',
    required this.targetAmount,
    required this.unit,
    required this.deadline,
    required this.voteDeadline,
    required this.createdAt,
    required this.expReward,
    this.heroExpReward = 50,
    this.heroGoldReward = 100,
    this.upvotes = const [],
    this.downvotes = const [],
    this.isApproved = false,
    this.isRejected = false,
    this.rejectionReason,
    this.rejectedAt,
    this.assignedHeroIds = const [],
    this.requiredPerHero = 0,
    this.heroProgress = const {},
    this.heroCompletionApproved = const {},
    this.isCompleted = false,
    this.completedAt,
  });

  factory GuildQuestModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAt =
        (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return GuildQuestModel(
      id: id,
      guildId: map['guildId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      attribute: map['attribute'] as String? ?? 'STRENGTH',
      targetAmount: map['targetAmount'] as int? ?? 0,
      unit: map['unit'] as String? ?? '',
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Doc cũ chưa có voteDeadline → mặc định 1 ngày kể từ lúc tạo
      voteDeadline: (map['voteDeadline'] as Timestamp?)?.toDate() ??
          createdAt.add(const Duration(days: 1)),
      createdAt: createdAt,
      expReward: map['expReward'] as int? ?? 150,
      heroExpReward: map['heroExpReward'] as int? ?? 50,
      heroGoldReward: map['heroGoldReward'] as int? ?? 100,
      upvotes: List<String>.from(map['upvotes'] ?? []),
      downvotes: List<String>.from(map['downvotes'] ?? []),
      isApproved: map['isApproved'] as bool? ?? false,
      isRejected: map['isRejected'] as bool? ?? false,
      rejectionReason: map['rejectionReason'] as String?,
      rejectedAt: (map['rejectedAt'] as Timestamp?)?.toDate(),
      assignedHeroIds: List<String>.from(map['assignedHeroIds'] ?? []),
      requiredPerHero: map['requiredPerHero'] as int? ?? 0,
      heroProgress: Map<String, int>.from(map['heroProgress'] ?? {}),
      heroCompletionApproved: Map<String, bool>.from(
        map['heroCompletionApproved'] ?? {},
      ),
      isCompleted: map['isCompleted'] as bool? ?? false,
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory GuildQuestModel.fromDoc(DocumentSnapshot doc) {
    return GuildQuestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'guildId': guildId,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'attribute': attribute,
      'targetAmount': targetAmount,
      'unit': unit,
      'deadline': Timestamp.fromDate(deadline),
      'voteDeadline': Timestamp.fromDate(voteDeadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'expReward': expReward,
      'heroExpReward': heroExpReward,
      'heroGoldReward': heroGoldReward,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'isApproved': isApproved,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
      'rejectedAt': rejectedAt == null ? null : Timestamp.fromDate(rejectedAt!),
      'assignedHeroIds': assignedHeroIds,
      'requiredPerHero': requiredPerHero,
      'heroProgress': heroProgress,
      'heroCompletionApproved': heroCompletionApproved,
      'isCompleted': isCompleted,
      'completedAt': completedAt == null
          ? null
          : Timestamp.fromDate(completedAt!),
    };
  }

  GuildQuestModel copyWith({
    String? title,
    String? description,
    String? attribute,
    int? targetAmount,
    String? unit,
    DateTime? deadline,
    DateTime? voteDeadline,
    int? expReward,
    int? heroExpReward,
    int? heroGoldReward,
    List<String>? upvotes,
    List<String>? downvotes,
    bool? isApproved,
    bool? isRejected,
    String? rejectionReason,
    DateTime? rejectedAt,
    List<String>? assignedHeroIds,
    int? requiredPerHero,
    Map<String, int>? heroProgress,
    Map<String, bool>? heroCompletionApproved,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return GuildQuestModel(
      id: id,
      guildId: guildId,
      createdBy: createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      attribute: attribute ?? this.attribute,
      targetAmount: targetAmount ?? this.targetAmount,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      voteDeadline: voteDeadline ?? this.voteDeadline,
      createdAt: createdAt,
      expReward: expReward ?? this.expReward,
      heroExpReward: heroExpReward ?? this.heroExpReward,
      heroGoldReward: heroGoldReward ?? this.heroGoldReward,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      assignedHeroIds: assignedHeroIds ?? this.assignedHeroIds,
      requiredPerHero: requiredPerHero ?? this.requiredPerHero,
      heroProgress: heroProgress ?? this.heroProgress,
      heroCompletionApproved:
          heroCompletionApproved ?? this.heroCompletionApproved,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
