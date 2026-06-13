import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

/// Màn hình quản lý tài khoản dùng chung cho cả Hero (con em) và
/// Guardian (phụ huynh): xem thông tin, đổi tên hiển thị, đổi mật khẩu,
/// đăng xuất.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _bg = Color(0xFFFCF9F0);
  static const _ink = Color(0xFF1C1C17);
  static const _gold = Color(0xFFD4AF37);
  static const _muted = Color(0xFF7F7663);
  static const _danger = Color(0xFFBA1A1A);

  AccountModel? _account;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final account = await AuthService.getCurrentAccount();
    if (!mounted) return;
    setState(() {
      _account = account;
      _isLoading = false;
    });
  }

  // ─── Đăng xuất ─────────────────────────────────────────────────────────────
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

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _danger : _ink,
      ),
    );
  }

  // ─── Đổi tên hiển thị ──────────────────────────────────────────────────────
  Future<void> _editDisplayName() async {
    final account = _account;
    if (account == null) return;

    final controller = TextEditingController(text: account.displayName);
    bool saving = false;

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _bg,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: _ink, width: 2),
              ),
              title: Text(
                'ĐỔI TÊN HIỂN THỊ',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              content: _BrutalField(
                controller: controller,
                hint: 'Tên mới',
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'HỦY',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      color: _muted,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final value = controller.text.trim();
                          if (value.isEmpty) return;
                          setDialogState(() => saving = true);
                          try {
                            await AuthService.updateDisplayName(
                              uid: account.uid,
                              role: account.role,
                              newDisplayName: value,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, value);
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: _danger,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _ink,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: _ink, width: 2),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: _ink,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'LƯU',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (newName != null && mounted) {
      setState(() {
        _account = AccountModel(
          uid: account.uid,
          email: account.email,
          displayName: newName,
          role: account.role,
          createdAt: account.createdAt,
        );
      });
      _snack('Đã cập nhật tên hiển thị.');
    }
  }

  // ─── Đổi mật khẩu ──────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _bg,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: _ink, width: 2),
              ),
              title: Text(
                'ĐỔI MẬT KHẨU',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrutalField(
                    controller: currentCtrl,
                    hint: 'Mật khẩu hiện tại',
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _BrutalField(
                    controller: newCtrl,
                    hint: 'Mật khẩu mới',
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  _BrutalField(
                    controller: confirmCtrl,
                    hint: 'Nhập lại mật khẩu mới',
                    obscure: true,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _danger,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'HỦY',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      color: _muted,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final current = currentCtrl.text;
                          final next = newCtrl.text;
                          final confirm = confirmCtrl.text;

                          if (current.isEmpty ||
                              next.isEmpty ||
                              confirm.isEmpty) {
                            setDialogState(
                              () => error = 'Vui lòng điền đầy đủ các ô.',
                            );
                            return;
                          }
                          if (next.length < 6) {
                            setDialogState(
                              () => error =
                                  'Mật khẩu mới cần ít nhất 6 ký tự.',
                            );
                            return;
                          }
                          if (next != confirm) {
                            setDialogState(
                              () => error = 'Mật khẩu nhập lại không khớp.',
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            await AuthService.changePassword(
                              currentPassword: current,
                              newPassword: next,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              saving = false;
                              error = AuthService.getErrorMessage(e);
                            });
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                              error = e.toString();
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _ink,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: _ink, width: 2),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: _ink,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'LƯU',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok == true) {
      _snack('Đã đổi mật khẩu thành công.');
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final account = _account;
    final isGuardian = account?.isGuardian ?? false;
    final accentColor = isGuardian ? const Color(0xFF77574D) : _gold;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: Text(
          'ACCOUNT',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _ink))
          : account == null
              ? Center(
                  child: Text(
                    'Không tải được thông tin tài khoản.',
                    style: GoogleFonts.spaceGrotesk(color: _muted),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileCard(account, accentColor),
                      const SizedBox(height: 32),
                      _buildSectionLabel('THÔNG TIN CÁ NHÂN', accentColor),
                      _buildMenuItem(
                        icon: Icons.badge_outlined,
                        label: 'Đổi tên hiển thị',
                        iconColor: accentColor,
                        onTap: _editDisplayName,
                      ),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Đổi mật khẩu',
                        iconColor: accentColor,
                        onTap: _changePassword,
                      ),
                      const SizedBox(height: 32),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard(AccountModel account, Color accentColor) {
    final initial = account.displayName.isNotEmpty
        ? account.displayName[0].toUpperCase()
        : '?';
    final roleLabel = account.isGuardian ? 'GUARDIAN' : 'HERO';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: _ink, width: 3),
        boxShadow: const [BoxShadow(color: _ink, offset: Offset(6, 6))],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: _ink, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: accentColor,
                  child: Text(
                    roleLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  account.displayName.isEmpty ? '—' : account.displayName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.email,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, Color bg) {
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.only(bottom: 0),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border(
          left: const BorderSide(color: _ink, width: 2),
          right: const BorderSide(color: _ink, width: 2),
          bottom: BorderSide(
            color: _ink.withValues(alpha: 0.12),
            width: 2,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: _ink.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: _danger, width: 2),
        boxShadow: const [BoxShadow(color: _danger, offset: Offset(4, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoggingOut ? null : _handleLogout,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.logout, color: _danger, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'ĐĂNG XUẤT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _danger,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (_isLoggingOut)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: _danger,
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(Icons.chevron_right, color: _danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ô nhập liệu theo phong cách neo-brutalist của app.
class _BrutalField extends StatelessWidget {
  const _BrutalField({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: const Color(0xFF1C1C17),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFB8B3A6),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
