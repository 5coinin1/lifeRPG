import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/boss_raid_model.dart';
import '../models/hero_model.dart';
import '../services/boss_raid_service.dart';
import '../widget/boss_reward_dialog.dart';

class BossRaidScreen extends StatefulWidget {
  final String guildId;
  final String? currentMemberId;
  final bool canAttack;

  const BossRaidScreen({
    super.key,
    required this.guildId,
    this.currentMemberId,
    this.canAttack = true,
  });

  @override
  State<BossRaidScreen> createState() => _BossRaidScreenState();
}

class _BossRaidScreenState extends State<BossRaidScreen>
    with TickerProviderStateMixin {
  final BossRaidService _raidService = BossRaidService();

  // Boss stats
  int _bossMaxHp = BossRaidService.fallbackBoss.maxHp;
  int _bossCurrentHp = BossRaidService.fallbackBoss.maxHp;
  String _bossName = 'THE PROCRASTINATION DRAGON';
  String _bossPhase = 'ENRAGED';

  // Player / hero info
  String? _uid;
  String _displayName = 'Hero';
  String _characterPath = 'STR';
  int _heroHp = 100;
  int _heroStamina = 100;
  int _heroMana = 100;
  String _heroStatus = 'active';

  // Battle state
  bool _isAttacking = false;
  String? _damageText;
  String? _skillUsed;

  // Leaderboard
  List<Map<String, dynamic>> _leaderboard = [];
  List<RaidHeroSkill> _skills = [];
  StreamSubscription? _raidSub;
  StreamSubscription? _raidStateSub;
  StreamSubscription? _skillSub;

  // Animations
  late AnimationController _bossShakeCtrl;
  late Animation<double> _bossShakeAnim;
  late AnimationController _bossGlowCtrl;
  late Animation<double> _bossGlowAnim;
  late AnimationController _damagePopCtrl;
  late Animation<double> _damagePopAnim;

  IconData _skillIcon(RaidHeroSkill skill) {
    switch (skill.iconKey) {
      case 'fire':
        return Icons.local_fire_department;
      case 'heal':
        return Icons.health_and_safety;
      case 'meteor':
        return Icons.blur_circular;
      case 'revive':
        return Icons.restart_alt;
      case 'shield':
        return Icons.shield;
      case 'speed':
        return Icons.speed;
      case 'sun':
        return Icons.brightness_high;
      case 'target':
        return Icons.gps_fixed;
      default:
        return Icons.flash_on;
    }
  }

  String _resourceLabel(RaidHeroSkill skill) {
    final label = switch (skill.resourceType) {
      RaidResourceType.stamina => 'STM',
      RaidResourceType.mana => 'MP',
      RaidResourceType.hp => 'HP',
      RaidResourceType.none => 'FREE',
    };
    return skill.resourceType == RaidResourceType.none
        ? label
        : '${skill.resourceCost} $label';
  }

  String _skillEffectLabel(RaidHeroSkill skill) {
    return switch (skill.effect) {
      RaidSkillEffect.damage => 'DMG',
      RaidSkillEffect.heal => 'HEAL',
      RaidSkillEffect.revive => 'REVIVE',
    };
  }

  @override
  void initState() {
    super.initState();
    _uid = widget.currentMemberId ?? FirebaseAuth.instance.currentUser?.uid;

    _bossShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bossShakeAnim = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(CurvedAnimation(parent: _bossShakeCtrl, curve: Curves.elasticIn));

    _bossGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bossGlowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_bossGlowCtrl);

    _damagePopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _damagePopAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _damagePopCtrl, curve: Curves.easeOut));

    _loadHeroData();
    _processBossAttack();
    _listenRaid();
    _listenSkills();
  }

  Future<void> _loadHeroData() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('heroes')
          .doc(_uid)
          .get();
      if (doc.exists && mounted) {
        final hero = HeroModel.fromMap({...doc.data()!, 'uid': doc.id});
        setState(() {
          _displayName = hero.displayName;
          _characterPath = hero.characterPath;
          _heroHp = hero.hp;
          _heroStamina = hero.stamina;
          _heroMana = hero.mana;
          _heroStatus = hero.status;
        });
      }
    } catch (_) {}
  }

  Future<void> _processBossAttack() async {
    try {
      final skill = await _raidService.processDueBossAttack(widget.guildId);
      if (skill != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Boss used ${skill.name} on active raiders.')),
        );
        _loadHeroData();
      }
    } catch (_) {}
  }

  void _listenRaid() {
    _raidStateSub = _raidService.raidStateStream(widget.guildId).listen((
      state,
    ) {
      if (!mounted) return;
      setState(() {
        _bossMaxHp = state.bossMaxHp;
        _bossCurrentHp = state.currentHp.clamp(0, _bossMaxHp);
        _bossName = state.bossName;
        _bossPhase = state.bossPhase;
      });
    });
    _raidSub = _raidService.leaderboardStream(widget.guildId).listen((entries) {
      if (mounted) setState(() => _leaderboard = entries);
    });
  }

  void _listenSkills() {
    if (_uid == null || !widget.canAttack) return;
    _skillSub = _raidService.skillsForHeroStream(_uid!).listen((skills) {
      if (mounted) setState(() => _skills = skills);
    });
  }

  Future<void> _useSkill(RaidHeroSkill skill) async {
    if (_isAttacking || _uid == null || !widget.canAttack) return;
    setState(() => _isAttacking = true);

    try {
      final result = await _raidService.useSkill(
        guildId: widget.guildId,
        heroId: _uid!,
        skillId: skill.id,
      );

      // Đòn đánh bị chặn (thiếu mana/stamina, đang hồi sinh...) → báo nhẹ.
      if (!result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result.message ?? 'Cannot use this skill right now.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFBA1A1A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isAttacking = false);
        return;
      }

      setState(() {
        _bossCurrentHp = result.bossHp;
        _heroHp = result.heroHp;
        _heroStamina = result.heroStamina;
        _heroMana = result.heroMana;
        _damageText = _resultText(result);
        _skillUsed = skill.name;
      });

      _bossShakeCtrl.forward(from: 0);
      _damagePopCtrl.forward(from: 0);

      // Boss vừa bị tiêu diệt → hiện bảng chúc mừng + phần thưởng ngay.
      if (result.defeated && mounted) {
        await showBossRewardDialog(
          context,
          bossName: _bossName,
          rewards: result.rewards,
        );
        // Đã xem ngay tại đây → đánh dấu đọc để không hiện lại lúc về home.
        if (_uid != null) {
          await _raidService.markAllNotificationsRead(_uid!);
        }
      } else {
        _processBossAttack();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isAttacking = false;
        _damageText = null;
        _skillUsed = null;
      });
    }
  }

  String _resultText(RaidSkillResult result) {
    if (result.skill.effect == RaidSkillEffect.damage) {
      return result.critical ? 'CRIT! -${result.amount}' : '-${result.amount}';
    }
    if (result.skill.effect == RaidSkillEffect.heal) {
      return '+${result.amount} HP';
    }
    return 'REVIVE +${result.amount} HP';
  }

  Color _pathColor(String path) {
    switch (path) {
      case 'INT':
        return const Color(0xFF7B1FA2);
      case 'AGI':
        return const Color(0xFF00897B);
      case 'SPI':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFFE53935);
    }
  }

  IconData _pathIcon(String path) {
    switch (path) {
      case 'INT':
        return Icons.auto_awesome;
      case 'AGI':
        return Icons.speed;
      case 'SPI':
        return Icons.brightness_high;
      default:
        return Icons.fitness_center;
    }
  }

  double get _bossHpPercent =>
      _bossMaxHp > 0 ? (_bossCurrentHp / _bossMaxHp).clamp(0.0, 1.0) : 0.0;

  @override
  void dispose() {
    _raidSub?.cancel();
    _raidStateSub?.cancel();
    _skillSub?.cancel();
    _bossShakeCtrl.dispose();
    _bossGlowCtrl.dispose();
    _damagePopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = _skills;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white70,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: const Color(0xFFBA1A1A),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BOSS RAID',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: _pathColor(_characterPath)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                Icon(
                  _pathIcon(_characterPath),
                  color: _pathColor(_characterPath),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _characterPath,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _pathColor(_characterPath),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBossPanel(),
            if (widget.canAttack) _buildSkillsPanel(skills),
            _buildLeaderboard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── BOSS PANEL ────────────────────────────────────────────────────────────────
  Widget _buildBossPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0010), Color(0xFF0A0A0F)],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Boss illustration
          AnimatedBuilder(
            animation: Listenable.merge([_bossShakeAnim, _bossGlowAnim]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  sin(_bossShakeCtrl.value * pi * 8) * _bossShakeAnim.value,
                  -28,
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFBA1A1A,
                        ).withOpacity(_bossGlowAnim.value * 0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: _buildBossGraphic(),
                ),
              );
            },
          ),
          // Damage pop text
          if (_damageText != null)
            Positioned(
              top: 10,
              child: AnimatedBuilder(
                animation: _damagePopAnim,
                builder: (ctx, child) => Transform.translate(
                  offset: Offset(0, -40 * _damagePopAnim.value),
                  child: Opacity(
                    opacity: 1 - _damagePopAnim.value,
                    child: Text(
                      _damageText!,
                      style: TextStyle(
                        fontSize: _damageText!.contains('CRIT') ? 28 : 24,
                        fontWeight: FontWeight.w900,
                        color: _damageText!.contains('CRIT')
                            ? const Color(0xFFFFD600)
                            : const Color(0xFFFF5252),
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Boss info overlay (bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _bossName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBA1A1A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    _bossPhase,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
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

  Widget _buildBossGraphic() {
    return Container(
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFBA1A1A).withOpacity(0.4),
                width: 2,
              ),
            ),
          ),
          // HP ring
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: _bossHpPercent,
              strokeWidth: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                _bossHpPercent > 0.5
                    ? const Color(0xFF4CAF50)
                    : _bossHpPercent > 0.25
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFBA1A1A),
              ),
            ),
          ),
          // Boss image with vignette corners
          ClipOval(
            child: SizedBox(
              width: 186,
              height: 186,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return RadialGradient(
                    center: Alignment.center,
                    radius: 0.85,
                    colors: const [
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.network(
                  'https://eldenring.wiki.fextralife.com/file/Elden-Ring/bayle_the_dread_bosses_elden_ring_wiki_1200px.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      const Text('🐉', style: TextStyle(fontSize: 72)),
                ),
              ),
            ),
          ),
          // HP % + số máu (nổi bật) — overlay đáy vòng tròn
          Positioned(
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_bossHpPercent * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: 0.5,
                      color: _bossHpPercent > 0.5
                          ? const Color(0xFF66E07A)
                          : _bossHpPercent > 0.25
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFFF6B6B),
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_bossCurrentHp / $_bossMaxHp HP',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SKILLS PANEL ──────────────────────────────────────────────────────────────
  Widget _buildSkillsPanel(List<RaidHeroSkill> skills) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _pathIcon(_characterPath),
                color: _pathColor(_characterPath),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '$_characterPath SKILLS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _pathColor(_characterPath),
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (_skillUsed != null)
                Text(
                  _skillUsed!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildResourceChip('HP', _heroHp, const Color(0xFFE53935)),
              const SizedBox(width: 8),
              _buildResourceChip('STM', _heroStamina, const Color(0xFF00897B)),
              const SizedBox(width: 8),
              _buildResourceChip('MP', _heroMana, const Color(0xFF7B1FA2)),
            ],
          ),
          const SizedBox(height: 14),
          if (!widget.canAttack)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Guardian view only. Heroes use unlocked guild quest skills.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else if (skills.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'No unlocked guild quest skills yet.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: skills.length,
            itemBuilder: (ctx, i) => _buildSkillButton(skills[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSkillButton(RaidHeroSkill skill) {
    final color = Color(skill.colorValue);
    final isSelected = _skillUsed == skill.name && _isAttacking;

    return GestureDetector(
      onTap: _isAttacking || _heroStatus == 'reviving' || !widget.canAttack
          ? null
          : () => _useSkill(skill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : const Color(0xFF1A1A2E),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(_skillIcon(skill), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${_skillEffectLabel(skill)} · ${_resourceLabel(skill)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LEADERBOARD ───────────────────────────────────────────────────────────────
  Widget _buildLeaderboard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border.all(color: Colors.white10, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.leaderboard,
                  color: Color(0xFFFED65B),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'DAMAGE LEADERBOARD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFED65B),
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_leaderboard.length} raiders',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),
          // Rows
          if (_leaderboard.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No damage dealt yet.\nBe the first to strike!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(_leaderboard.length, (i) {
              final entry = _leaderboard[i];
              final isMe = entry['heroId'] == _uid;
              final path = entry['characterPath'] as String? ?? 'STR';
              return _buildLeaderboardRow(i + 1, entry, isMe, path);
            }),
          // My entry if not in top list
          if (_leaderboard.isNotEmpty &&
              !_leaderboard.any((e) => e['heroId'] == _uid))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _pathColor(_characterPath).withOpacity(0.1),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  const Text(
                    '—',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _displayName,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const Spacer(),
                  const Text(
                    '0 DMG',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
    int rank,
    Map<String, dynamic> entry,
    bool isMe,
    String path,
  ) {
    final damage = entry['damage'] as int;
    final maxDmg = (_leaderboard.isNotEmpty
        ? (_leaderboard.first['damage'] as int)
        : 1);
    final barWidth = maxDmg > 0 ? damage / maxDmg : 0.0;
    final rankColors = [
      const Color(0xFFFFD600),
      const Color(0xFFBDBDBD),
      const Color(0xFFBF6F3C),
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : Colors.white38;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: isMe ? _pathColor(path).withOpacity(0.08) : Colors.transparent,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
          left: isMe
              ? BorderSide(color: _pathColor(path), width: 3)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: rank <= 3
                    ? Text(
                        ['🥇', '🥈', '🥉'][rank - 1],
                        style: const TextStyle(fontSize: 18),
                      )
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
              ),
              Icon(_pathIcon(path), color: _pathColor(path), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry['name'] as String? ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.normal,
                    color: isMe ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              Text(
                '${_fmtNum(damage)} DMG',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: barWidth,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFFD600)
                        : _pathColor(path),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
