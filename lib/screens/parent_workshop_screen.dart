import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hero_model.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class ParentWorkshopScreen extends StatefulWidget {
  const ParentWorkshopScreen({Key? key}) : super(key: key);

  @override
  State<ParentWorkshopScreen> createState() => _ParentWorkshopScreenState();
}

class _ParentWorkshopScreenState extends State<ParentWorkshopScreen> {
  // Forge Quest Form States
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(
    text: '1',
  );
  final TextEditingController _expController = TextEditingController(
    text: '100',
  );
  final TextEditingController _goldController = TextEditingController(
    text: '50',
  );
  String _selectedAttribute = 'STRENGTH';
  String _selectedDifficulty = 'EASY';

  // State
  String? _guardianUid;
  List<HeroModel> _heroes = [];
  String? _selectedHeroId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final account = await AuthService.getCurrentAccount();
    if (account != null) {
      if (mounted) setState(() => _guardianUid = account.uid);
      final heroes = await AuthService.getHeroesOfGuardian(account.uid);
      if (mounted) {
        setState(() {
          _heroes = heroes;
          if (_heroes.isNotEmpty) {
            _selectedHeroId = _heroes.first.uid;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _expController.dispose();
    _goldController.dispose();
    super.dispose();
  }

  void _handleForgeQuest() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      _showErrorDialog(
        'BLUEPRINT INCOMPLETE',
        'A valid quest blueprint requires both a Title and a Description.',
      );
      return;
    }
    if (_guardianUid == null) return;

    try {
      int targetCount = int.tryParse(_targetController.text) ?? 1;
      int expReward = int.tryParse(_expController.text) ?? 100;
      int goldReward = int.tryParse(_goldController.text) ?? 50;

      if (_selectedHeroId == null) {
        await TaskService.createTaskForAllHeroes(
          guardianId: _guardianUid!,
          title: title,
          description: desc,
          expReward: expReward,
          goldReward: goldReward,
          targetCount: targetCount,
          difficulty: _selectedDifficulty,
        );
      } else {
        await TaskService.createTaskForHero(
          guardianId: _guardianUid!,
          heroId: _selectedHeroId!,
          title: title,
          description: desc,
          expReward: expReward,
          goldReward: goldReward,
          targetCount: targetCount,
          difficulty: _selectedDifficulty,
        );
      }

      if (mounted) {
        setState(() {
          _titleController.clear();
          _descController.clear();
          _targetController.text = '1';
          _expController.text = '100';
          _goldController.text = '50';
          _selectedAttribute = 'STRENGTH';
          _selectedDifficulty = 'EASY';
        });
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog('BLUEPRINT FAILED', 'Failed to forge quest: $e');
    }
  }

  String _heroNameForTask(TaskModel task) {
    return _heroes
            .cast<HeroModel?>()
            .firstWhere((hero) => hero?.uid == task.heroId, orElse: () => null)
            ?.displayName ??
        task.heroId;
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'HARD':
        return const Color(0xFFBA1A1A);
      case 'MEDIUM':
        return const Color(0xFF8F7100);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  void _setDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      switch (difficulty) {
        case 'HARD':
          _targetController.text = '5';
          _expController.text = '300';
          _goldController.text = '150';
          break;
        case 'MEDIUM':
          _targetController.text = '3';
          _expController.text = '200';
          _goldController.text = '100';
          break;
        default:
          _targetController.text = '1';
          _expController.text = '100';
          _goldController.text = '50';
      }
    });
  }

  void _approveQuest(TaskModel quest) async {
    try {
      await TaskService.approveTask(quest, 'Quest Approved via Workshop');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QUEST APPROVED: ${quest.title}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      // Ignore for now
    }
  }

  void _rejectQuest(TaskModel quest) async {
    try {
      await TaskService.rejectTask(quest, 'Quest Rejected via Workshop');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QUEST REJECTED: ${quest.title}'),
            backgroundColor: const Color(0xFFBA1A1A),
          ),
        );
      }
    } catch (e) {}
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFCF9F0),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFFBA1A1A),
            fontSize: 16,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1C17),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'REVISE BLUEPRINT',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFCF9F0),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF1C1C17), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'BLUEPRINT FORGED',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF735C00),
            fontSize: 16,
          ),
        ),
        content: Text(
          'Your new quest has been broadcasted to the Sunstone Review Chamber.',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1C17),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C17),
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'ACKNOWLEDGE',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: Stack(
        children: [
          // Background dotted pattern
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            child: Column(
              children: [
                // Scrollable workspace
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- FORGE NEW QUEST CONTAINER ---
                        _buildForgeQuestCard(),

                        const SizedBox(height: 32),

                        StreamBuilder<List<TaskModel>>(
                          stream: _guardianUid != null
                              ? TaskService.getPendingTasksForGuardian(
                                  _guardianUid!,
                                )
                              : const Stream.empty(),
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
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.architecture_outlined,
                                          color: Color(0xFF77574D),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'REVIEW CHAMBER',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF1C1C17),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tasks.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        color: const Color(0xFFFCD385),
                                        child: Text(
                                          '${tasks.length} PENDING',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFF1C1C17),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 2,
                                  color: const Color(0xFF1C1C17),
                                ),
                                const SizedBox(height: 16),

                                if (tasks.isEmpty)
                                  _buildEmptyChamber()
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: tasks.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) =>
                                        _buildReviewCard(tasks[index]),
                                  ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),
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

  // --- FORGE QUEST CARD ---
  Widget _buildForgeQuestCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F0),
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1C1C17), offset: Offset(4, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row
          Row(
            children: [
              const Icon(Icons.edit_road, color: Color(0xFF1C1C17), size: 20),
              const SizedBox(width: 8),
              Text(
                'FORGE NEW QUEST',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1C1C17),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Assignee Dropdown
          _buildFormLabel('ASSIGN TO HERO'),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEBE8DF),
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedHeroId,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1C1C17),
                ),
                dropdownColor: const Color(0xFFFCF9F0),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C17),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHeroId = newValue;
                  });
                },
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('ALL HEROES'),
                  ),
                  ..._heroes.map((hero) {
                    return DropdownMenuItem<String?>(
                      value: hero.uid,
                      child: Text(hero.displayName),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quest Title field
          _buildFormLabel('QUEST TITLE'),
          Container(
            color: const Color(0xFFEBE8DF),
            child: TextField(
              controller: _titleController,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. The Sunstone Retrieval',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFACA390),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF735C00), width: 2.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          _buildFormLabel('DESCRIPTION'),
          Container(
            color: const Color(0xFFEBE8DF),
            child: TextField(
              controller: _descController,
              maxLines: 3,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Describe the journey and objectives...',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFFACA390),
                ),
                contentPadding: const EdgeInsets.all(12),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Color(0xFF735C00), width: 2.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Attribute & Complexity row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attribute Focus
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('ATTRIBUTE FOCUS'),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE8DF),
                        border: Border.all(
                          color: const Color(0xFF1C1C17),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAttribute,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF1C1C17),
                          ),
                          dropdownColor: const Color(0xFFFCF9F0),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1C1C17),
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedAttribute = newValue;
                              });
                            }
                          },
                          items:
                              <String>[
                                'STRENGTH',
                                'INTELLECT',
                                'SPIRIT',
                                'AGILITY',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFormLabel('DIFFICULTY'),
          Row(
            children: [
              _buildDifficultyOption('EASY', Icons.flag_outlined),
              const SizedBox(width: 8),
              _buildDifficultyOption(
                'MEDIUM',
                Icons.local_fire_department_outlined,
              ),
              const SizedBox(width: 8),
              _buildDifficultyOption('HARD', Icons.whatshot),
            ],
          ),
          const SizedBox(height: 16),

          // TARGET & REWARDS row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('TARGET (MỐC)'),
                    _buildNumberInput(_targetController),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('EXP REWARD'),
                    _buildNumberInput(_expController),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormLabel('GOLD REWARD'),
                    _buildNumberInput(_goldController),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _handleForgeQuest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF705345), // Chestnut Brown
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Color(0xFF1C1C17), width: 2),
                ),
              ),
              child: Text(
                'FINALIZE BLUEPRINT',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF77574D),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller) {
    return Container(
      height: 48,
      color: const Color(0xFFEBE8DF),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: Color(0xFF735C00), width: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String value, IconData icon) {
    final selected = _selectedDifficulty == value;
    final color = _difficultyColor(value);
    return Expanded(
      child: GestureDetector(
        onTap: () => _setDifficulty(value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFEBE8DF),
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : const Color(0xFF1C1C17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REVIEW CARD ---
  Widget _buildReviewCard(TaskModel quest) {
    final heroName = _heroNameForTask(quest);
    final difficultyColor = _difficultyColor(quest.difficulty);
    final hasGuildProgressToReview =
        quest.source == 'guild' &&
        quest.currentProgress > quest.guildApprovedProgress;
    final canReview =
        quest.status == 'pending_approval' || hasGuildProgressToReview;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildMetaChip('HERO: $heroName', const Color(0xFF1C1C17)),
                  _buildMetaChip(quest.difficulty, difficultyColor),
                  if (quest.source == 'guild')
                    _buildMetaChip('GUILD', const Color(0xFF77574D)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                quest.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF705345),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description text
          Text(
            quest.description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4D4635),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Metadata row (Level / Party size)
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                color: Color(0xFF735C00),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '${quest.goldReward}G',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7F7663),
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.star_outline,
                color: Color(0xFF7F7663),
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                '${quest.expReward} EXP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7F7663),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESS: ${quest.currentProgress}/${quest.targetCount}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C17),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: quest.status == 'pending_approval'
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFEBE8DF),
                child: Text(
                  quest.status == 'pending_approval'
                      ? 'WAITING REVIEW'
                      : 'IN PROGRESS',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Action Buttons
          if (canReview)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _approveQuest(quest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: Color(0xFF1C1C17),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'APPROVE',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _rejectQuest(quest),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA1A1A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: Color(0xFF1C1C17),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'REJECT',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: color,
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyChamber() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.rule_folder_outlined,
              size: 32,
              color: Color(0xFF7F7663),
            ),
            const SizedBox(height: 10),
            Text(
              'NO BLUEPRINTS IN CHAMBER',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No new player submissions are currently waiting for guild approval.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.5,
                color: const Color(0xFF7F7663),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- BACKGROUND DOT PATTERN ---
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
