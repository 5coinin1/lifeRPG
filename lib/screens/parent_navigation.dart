import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_screen.dart';
import 'parent_workshop_screen.dart';
import 'guild_entry_screen.dart';
import '../services/auth_service.dart';
import '../models/guardian_model.dart';
import 'login_screen.dart';

class ParentNavigation extends StatefulWidget {
  const ParentNavigation({Key? key}) : super(key: key);

  @override
  State<ParentNavigation> createState() => _ParentNavigationState();
}

class _ParentNavigationState extends State<ParentNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ParentDashboardScreen(),
    const ParentWorkshopScreen(),
    const GuildEntryScreen(),
    const _ParentArchiveScreen(), // Archive tab placeholder matching the style
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF6F3EA),
          border: Border(top: BorderSide(color: Color(0xFF1C1C17), width: 2)),
        ),
        child: Row(
          children: [
            _buildNavItem(0, 'DASHBOARD', Icons.grid_view_sharp),
            _buildNavItem(1, 'WORKSHOP', Icons.construction),
            _buildNavItem(2, 'COMMUNITY', Icons.groups_outlined),
            _buildNavItem(3, 'ARCHIVE', Icons.receipt_long_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1C1C17) : Colors.transparent,
            border: isSelected
                ? const Border(
                    top: BorderSide(color: Color(0xFFD4AF37), width: 4),
                  )
                : const Border(
                    top: BorderSide(color: Colors.transparent, width: 4),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFF7F7663),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF7F7663),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-SCREEN FOR ARCHIVE TAB ---
class _ParentArchiveScreen extends StatefulWidget {
  const _ParentArchiveScreen({Key? key}) : super(key: key);

  @override
  State<_ParentArchiveScreen> createState() => _ParentArchiveScreenState();
}

class _ParentArchiveScreenState extends State<_ParentArchiveScreen> {
  GuardianModel? _guardian;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGuardian();
  }

  Future<void> _loadGuardian() async {
    try {
      final account = await AuthService.getCurrentAccount();
      if (account != null) {
        var guardian = await AuthService.getGuardian(account.uid);

        // Tự động tạo mã mời nếu tài khoản cũ chưa có mã
        if (guardian != null && guardian.inviteCode.isEmpty) {
          const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
          final random = math.Random();
          final newCode = String.fromCharCodes(
            Iterable.generate(
              6,
              (_) => chars.codeUnitAt(random.nextInt(chars.length)),
            ),
          );

          await FirebaseFirestore.instance
              .collection('guardians')
              .doc(guardian.uid)
              .update({'inviteCode': newCode});

          guardian = guardian.copyWith(inviteCode: newCode);
        }

        if (mounted) {
          setState(() {
            _guardian = guardian;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyInviteCode() async {
    if (_guardian != null && _guardian!.inviteCode.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _guardian!.inviteCode));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã sao chép mã ${_guardian!.inviteCode} vào khay nhớ tạm!',
          ),
          backgroundColor: const Color(0xFF1C1C17),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFF77574D), width: 8),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THE FAMILY MAP',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1C1C17),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'FAMILY INVITATION HUB',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF77574D),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  _buildSection(
                    title: 'FAMILY ACCESS',
                    titleBg: const Color(0xFF77574D),
                    titleColor: Colors.white,
                    children: [
                      _buildInviteCodeItem(),
                      _buildMenuItem(
                        icon: Icons.family_restroom,
                        label: 'Share code with heroes',
                        iconColor: const Color(0xFF77574D),
                        onTap: _copyInviteCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildSection(
                    title: 'LEGACY ARCHIVE & REPORTS',
                    titleBg: const Color(0xFF735C00),
                    titleColor: Colors.white,
                    children: [
                      _buildMenuItem(
                        icon: Icons.gavel_sharp,
                        label: 'Guild code of conduct',
                        iconColor: const Color(0xFF735C00),
                      ),
                      _buildMenuItem(
                        icon: Icons.payments_outlined,
                        label: 'Treasury logs',
                        iconColor: const Color(0xFF735C00),
                      ),
                      _buildMenuItem(
                        icon: Icons.emoji_events_outlined,
                        label: 'Hero milestones',
                        iconColor: const Color(0xFF735C00),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildSection(
                    title: 'ARCHIVE INFORMATION',
                    titleBg: const Color(0xFF1B6D24),
                    titleColor: Colors.white,
                    children: [
                      _buildMenuItem(
                        icon: Icons.auto_stories,
                        label: 'About the family archive',
                        iconColor: const Color(0xFF1B6D24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // ── ĐĂNG XUẤT ──────────────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(color: const Color(0xFFBA1A1A), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFBA1A1A), offset: Offset(4, 4)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoggingOut ? null : _handleLogout,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: Color(0xFFBA1A1A), size: 22),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'ĐĂNG XUẤT',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFBA1A1A),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              if (_isLoggingOut)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFBA1A1A),
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(Icons.chevron_right, color: Color(0xFFBA1A1A)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color titleBg,
    required Color titleColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: titleBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: titleColor,
              letterSpacing: 2,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1C1C17), width: 4)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInviteCodeItem() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF1C1C17).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _copyInviteCode,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, color: Color(0xFFD4AF37)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR UNIQUE CODE',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF77574D),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _inviteCodeText,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1C1C17),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share this code with your heroes to let them join your family.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7F7663),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFF1C1C17)),
                  onPressed: _copyInviteCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF1C1C17).withValues(alpha: 0.1),
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C17),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF1C1C17).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _inviteCodeText {
    if (_guardian?.inviteCode == null || _guardian!.inviteCode.isEmpty) {
      return '------';
    }

    return _guardian!.inviteCode;
  }
}
