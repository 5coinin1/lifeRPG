import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../models/hero_model.dart';
import '../models/boss_raid_model.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/boss_raid_service.dart';
import '../widget/boss_reward_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _heroUid;
  bool _progressSnackBarVisible = false;
  StreamSubscription<List<GameNotification>>? _notifSub;
  bool _showingNotif = false;

  @override
  void initState() {
    super.initState();
    _loadHero();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _loadHero() async {
    final account = await AuthService.getCurrentAccount();
    if (account != null && mounted) {
      setState(() {
        _heroUid = account.uid;
      });
      _listenNotifications(account.uid);
    }
  }

  /// Lắng nghe inbox thông báo — hiện bảng chúc mừng cho người đăng nhập sau
  /// khi guild đã hạ boss. Xử lý lần lượt từng thông báo rồi đánh dấu đã đọc.
  void _listenNotifications(String heroUid) {
    _notifSub = BossRaidService().notificationsStream(heroUid).listen((
      items,
    ) async {
      if (_showingNotif || items.isEmpty || !mounted) return;
      final notif = items.first;
      _showingNotif = true;
      await showBossRewardDialog(
        context,
        bossName: notif.bossName,
        rewards: notif.rewards,
      );
      await BossRaidService().markNotificationRead(heroUid, notif.id);
      _showingNotif = false;
    });
  }

  void _showProgressSavedSnackBar(String taskTitle) {
    if (_progressSnackBarVisible) return;

    _progressSnackBarVisible = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text('PROGRESS SAVED FOR: $taskTitle'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        )
        .closed
        .then((_) {
          _progressSnackBarVisible = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [


            // Level and Gold
            StreamBuilder<HeroModel?>(
              stream: _heroUid != null
                  ? AuthService.getHeroStream(_heroUid!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final hero = snapshot.data;
                final levelStr = hero?.level.toString() ?? "-";
                final goldStr = hero?.gold.toString() ?? "-";

                return Row(
                  children: [
                    Expanded(
                      child: _buildStatBox(
                        Icons.emoji_events,
                        "LEVEL",
                        levelStr,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatBox(
                        Icons.payments,
                        "GOLD PIECES",
                        goldStr,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Active Quests Title
            Row(
              children: [
                const Icon(Icons.colorize, size: 28, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  "ACTIVE\nQUESTS",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: const Color(0xFF1C1C17),
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                _buildSmallButton("SORT\nDIFFICULTY"),
                const SizedBox(width: 8),
                _buildSmallButton("FILTER:\nMAIN"),
              ],
            ),
            const SizedBox(height: 16),

            // Active Quests List
            if (_heroUid != null)
              StreamBuilder<List<TaskModel>>(
                stream: TaskService.getTasksForHero(_heroUid!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data ?? [];
                  // Lọc bỏ những task đã fail hoặc completed nếu muốn, hoặc hiển thị tất cả
                  final activeTasks = tasks
                      .where((t) => t.status == 'todo')
                      .toList();

                  if (activeTasks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1C1C17),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "NO ACTIVE QUESTS.\nENJOY YOUR REST.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF7F7663),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final task = activeTasks[index];
                      final difficulty = task.difficulty;
                      final diffColor = switch (difficulty) {
                        'HARD' => const Color(0xFFBA1A1A),
                        'MEDIUM' => const Color(0xFF5E35B1),
                        _ => const Color(0xFFD0C5AF),
                      };

                      return _buildQuestCard(
                        task: task,
                        title: task.title,
                        description: task.description,
                        difficulty: difficulty,
                        exp: task.expReward,
                        gold: task.goldReward,
                        statusLabel: "PROGRESS",
                        statusValue:
                            "${task.currentProgress} / ${task.targetCount}",
                        buttonText: task.currentProgress + 1 >= task.targetCount
                            ? "FINISH QUEST"
                            : "PROGRESS (+1)",
                        buttonColor: const Color(0xFFD4AF37),
                        difficultyColor: diffColor,
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            color: const Color(0xFFD4AF37),
            child: const Icon(Icons.inventory, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NEW LOOT!",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              Text(
                "LEGENDARY COFFEE BEANS",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdventurerStats() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ADVENTURER STATS",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            "HEALTH POINTS (HP)",
            "85 / 100",
            0.85,
            const Color(0xFFBA1A1A),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            "STAMINA (DAILY ENERGY)",
            "42 / 60",
            0.7,
            const Color(0xFF5E35B1),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    String value,
    double percent,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C17),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1C1C17),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: const Border(
                  right: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C17),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C1C17),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildSmallButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDDAD1),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C1C17),
        ),
      ),
    );
  }

  Widget _buildQuestCard({
    required TaskModel task,
    required String title,
    required String description,
    required String difficulty,
    required int exp,
    required int gold,
    required String statusLabel,
    required String statusValue,
    required String buttonText,
    required Color buttonColor,
    required Color difficultyColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(6, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Part
          Container(
            color: const Color(0xFFF6F3EA),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Row(
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  index <
                                      (difficulty == "HARD"
                                          ? 3
                                          : difficulty == "MEDIUM"
                                          ? 2
                                          : 1)
                                  ? difficultyColor
                                  : Colors.transparent,
                              border: Border.all(
                                color: difficultyColor,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$difficulty DIFFICULTY",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: difficultyColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1C17),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4D4635),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRewardTag(Icons.star, "$exp EXP"),
                    const SizedBox(width: 8),
                    _buildRewardTag(Icons.payments, "$gold GOLD"),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Part
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1C1C17), width: 2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusValue,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1C17),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await TaskService.incrementTaskProgress(task);
                        if (mounted) {
                          _showProgressSavedSnackBar(task.title);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ERROR: $e'),
                              backgroundColor: const Color(0xFFBA1A1A),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                      side: const BorderSide(
                        color: Color(0xFF1C1C17),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDDDAD1),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD4AF37),
            ),
          ),
        ],
      ),
    );
  }
}
