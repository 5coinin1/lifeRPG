import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../models/hero_model.dart';
import '../models/task_model.dart';
import 'hero_gear_view_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  String? _guardianUid;

  @override
  void initState() {
    super.initState();
    _loadGuardian();
  }

  Future<void> _loadGuardian() async {
    final account = await AuthService.getCurrentAccount();
    if (account != null) {
      if (mounted) {
        setState(() => _guardianUid = account.uid);
      }
    }
  }

  void _approveApproval(TaskModel task) async {
    try {
      await TaskService.approveTask(task, "Bố mẹ đã xác nhận!");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'APPROVED: ${task.title}',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFCF9F0),
            ),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  void _denyApproval(TaskModel task) async {
    try {
      await TaskService.rejectTask(task, "Chưa đạt yêu cầu, con làm lại nhé.");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'DENIED: ${task.title}',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFCF9F0),
            ),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Handle error
    }
  }

  void _showHeroDetails(HeroModel hero) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFCF9F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Color(0xFF1C1C17), width: 3),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF1C1C17),
                      width: 2,
                    ),
                  ),
                  child: Image.network(
                    'https://placehold.co/150x150/1C1C17/FCF9F0/png?text=HERO',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hero.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1C1C17),
                        ),
                      ),
                      Text(
                        'LEVEL ${hero.level} HERO',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF77574D),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(hero.status),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'HERO PERFORMANCE STATS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'HP [HEALTH]',
              hero.maxHp > 0 ? hero.hp / hero.maxHp : 0.0,
              '${hero.hp}/${hero.maxHp}',
              const Color(0xFFBA1A1A),
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'MP [MANA]',
              hero.maxMana > 0 ? hero.mana / hero.maxMana : 0.0,
              '${hero.mana}/${hero.maxMana}',
              const Color(0xFF1976D2),
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'SP [STAMINA]',
              hero.maxStamina > 0 ? hero.stamina / hero.maxStamina : 0.0,
              '${hero.stamina}/${hero.maxStamina}',
              const Color(0xFF1B6D24),
            ),
            const SizedBox(height: 12),
            _buildStatBar(
              'EXP [LEVEL ${hero.level}]',
              hero.level > 0
                  ? (hero.exp / (hero.level * 1000)).clamp(0.0, 1.0)
                  : 0.0,
              '${hero.exp}/${hero.level * 1000}',
              const Color(0xFFD4AF37),
            ),
            const SizedBox(height: 24),
            Text(
              'ATTRIBUTES',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAttributeChip(
                    'STR',
                    hero.strength,
                    const Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'INT',
                    hero.intellect,
                    const Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'SPI',
                    hero.spirit,
                    const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'AGI',
                    hero.agility,
                    const Color(0xFF455A64),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAttributeChip(
                    'GOLD',
                    hero.gold,
                    const Color(0xFF735C00),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAttributeChip(
                    'POINTS',
                    hero.statPoints,
                    const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1C1C17),
                      side: const BorderSide(
                        color: Color(0xFF1C1C17),
                        width: 2,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'BACK TO STAGE',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Custom action for giving gold directly
                      _showDirectGoldDialog(hero);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF735C00),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'AWARD GOLD',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectGoldDialog(HeroModel hero) {
    final heroName = hero.displayName;
    int amount = 100;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9F0),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFF1C1C17), width: 3),
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
            'DIRECT GOLD TRANSFER',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reward $heroName directly from the Treasury. This bypasses the quest checklist.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: const Color(0xFF7F7663),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (amount > 10) setDlgState(() => amount -= 10);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${amount}G',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      setDlgState(() => amount += 10);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7F7663),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await AuthService.awardGold(
                    heroUid: hero.uid,
                    amount: amount,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Granted $amount Gold to $heroName'),
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to transfer gold: $e'),
                      backgroundColor: const Color(0xFFBA1A1A),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1C17),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                'TRANSFER',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBar(
    String label,
    double percent,
    String valText,
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
              ),
            ),
            Text(
              valText,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE8DF),
            border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isReviving = status == 'reviving';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReviving ? const Color(0xFFBA1A1A) : const Color(0xFF2E7D32),
        border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
      ),
      child: Text(
        isReviving ? 'REVIVING' : 'ACTIVE',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAttributeChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF77574D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_guardianUid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF9F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: Stack(
        children: [
          // Dot Grid Background
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            child: Column(
              children: [
                // --- MAIN CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ACTIVE HEROES SECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACTIVE HEROES',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF77574D),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'PARTY STATUS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF7F7663),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(height: 2, color: const Color(0xFF77574D)),
                        const SizedBox(height: 16),

                        StreamBuilder<List<HeroModel>>(
                          stream: AuthService.heroesOfGuardianStream(
                            _guardianUid!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final heroes = snapshot.data ?? [];
                            if (heroes.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEBE8DF),
                                  border: Border.all(
                                    color: const Color(0xFF1C1C17),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'NO HEROES LINKED YET',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF77574D),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: heroes.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) =>
                                  _buildHeroCard(heroes[index]),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        StreamBuilder<List<TaskModel>>(
                          stream: TaskService.getPendingTasksForGuardian(
                            _guardianUid!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final tasks = snapshot.data ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PENDING APPROVALS',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF77574D),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (tasks.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        color: const Color(0xFFBA1A1A),
                                        child: Text(
                                          '${tasks.length} New',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 2,
                                  color: const Color(0xFF77574D),
                                ),
                                const SizedBox(height: 16),

                                if (tasks.isEmpty)
                                  _buildEmptyApprovals()
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: tasks.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) =>
                                        _buildApprovalCard(tasks[index]),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
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

  // --- BUILD HERO CARD ---
  Widget _buildHeroCard(HeroModel hero) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F0),
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1C1C17), width: 2),
                ),
                child: Image.network(
                  'https://placehold.co/150x150/1C1C17/FCF9F0/png?text=HERO',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Profile info & HP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          hero.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1C1C17),
                          ),
                        ),
                        _buildStatusBadge(hero.status),
                      ],
                    ),
                    Text(
                      'LEVEL ${hero.level} HERO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7F7663),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // HP bar
                    _buildStatBar(
                      'HP [HEALTH]',
                      hero.maxHp > 0 ? hero.hp / hero.maxHp : 0.0,
                      '${hero.hp}/${hero.maxHp}',
                      const Color(0xFFBA1A1A),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _showHeroDetails(hero),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1C1C17),
                      foregroundColor: const Color(0xFFFCF9F0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'VIEW QUESTS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      // Xem (read-only) loadout đang trang bị của con em.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HeroGearViewScreen(
                            heroUid: hero.uid,
                            heroName: hero.displayName,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1C1C17),
                      side: const BorderSide(
                        color: Color(0xFF1C1C17),
                        width: 2,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      'EQUIP GEAR',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _taskDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'HARD':
        return const Color(0xFFBA1A1A);
      case 'MEDIUM':
        return const Color(0xFF8F7100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  // --- BUILD APPROVAL CARD ---
  Widget _buildApprovalCard(TaskModel task) {
    final hasGuildProgressToReview =
        task.source == 'guild' &&
        task.currentProgress > task.guildApprovedProgress;
    final canReview =
        task.status == 'pending_approval' || hasGuildProgressToReview;

    return FutureBuilder<HeroModel?>(
      future: AuthService.getHero(task.heroId),
      builder: (context, snapshot) {
        final heroName = snapshot.data?.displayName ?? task.heroId;
        final difficultyColor = _taskDifficultyColor(task.difficulty);
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFCF9F0),
            border: Border.all(color: const Color(0xFF1C1C17), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Icon Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0C9C0),
                      border: Border.all(
                        color: const Color(0xFF1C1C17),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFF77574D),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUEST: ${task.title}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1C1C17),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTaskTag(
                              'HERO: $heroName',
                              const Color(0xFF1C1C17),
                            ),
                            _buildTaskTag(task.difficulty, difficultyColor),
                            if (task.source == 'guild')
                              _buildTaskTag('GUILD', const Color(0xFF77574D)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF4D4635),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Progress: ${task.currentProgress}/${task.targetCount} · Reward: ${task.expReward} EXP / ${task.goldReward}G',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7F7663),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Inline Actions
                  if (canReview) ...[
                    GestureDetector(
                      onTap: () => _approveApproval(task),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784), // Light green
                          border: Border.all(
                            color: const Color(0xFF1C1C17),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 18,
                          color: Color(0xFF1C1C17),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _denyApproval(task),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCDD2), // Light red/pink
                          border: Border.all(
                            color: const Color(0xFF1C1C17),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Color(0xFF1C1C17),
                        ),
                      ),
                    ),
                  ] else
                    _buildTaskTag('WAITING HERO', const Color(0xFF7F7663)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: color,
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyApprovals() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 36,
              color: Color(0xFF7F7663),
            ),
            const SizedBox(height: 12),
            Text(
              'ALL CLEAR IN THE CHAMBERS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No pending deeds require your seals or signatures.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: const Color(0xFF7F7663),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- BACKGROUND DOT PATERN ---
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0C5AF)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 1.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
        canvas.drawCircle(Offset(x + 10, y + 10), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
