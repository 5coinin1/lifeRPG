import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'account_settings_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thematic Header
            Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFF77574D), width: 8)),
              ),
              padding: const EdgeInsets.only(left: 24, top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "THE REALM MAP",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1C1C17),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SYSTEM CONFIGURATION HUB",
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
              title: "ACCOUNT",
              titleBg: const Color(0xFF77574D),
              titleColor: const Color(0xFFFFFFFF),
              children: [
                _buildMenuItem(
                  icon: Icons.person,
                  label: "Profile",
                  iconColor: const Color(0xFF77574D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(icon: Icons.security, label: "Security & Privacy", iconColor: const Color(0xFF77574D)),
                _buildMenuItem(icon: Icons.devices, label: "Linked Devices", iconColor: const Color(0xFF77574D)),
              ],
            ),
            const SizedBox(height: 40),

            _buildSection(
              title: "NOTIFICATIONS",
              titleBg: const Color(0xFF735C00),
              titleColor: const Color(0xFFFFFFFF),
              children: [
                _buildToggleItem(icon: Icons.notification_important, label: "Quest Alerts", iconColor: const Color(0xFF735C00), isOn: true),
                _buildToggleItem(icon: Icons.campaign, label: "Guild News", iconColor: const Color(0xFF735C00), isOn: false),
              ],
            ),
            const SizedBox(height: 40),

            _buildSection(
              title: "INTERFACE & SYSTEM",
              titleBg: const Color(0xFF1C1C17),
              titleColor: const Color(0xFFFCF9F0),
              children: [
                _buildDisabledItem(),
                _buildMenuItem(icon: Icons.volume_up, label: "Audio & SFX", iconColor: const Color(0xFF1C1C17)),
                _buildMenuItem(icon: Icons.format_size, label: "Text Size", iconColor: const Color(0xFF1C1C17)),
              ],
            ),
            const SizedBox(height: 40),

            _buildSection(
              title: "ARCHIVE INFORMATION",
              titleBg: const Color(0xFF1B6D24),
              titleColor: const Color(0xFFFFFFFF),
              children: [
                _buildMenuItem(icon: Icons.auto_stories, label: "About the Archive", iconColor: const Color(0xFF1B6D24)),
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
          bottom: BorderSide(color: const Color(0xFF1C1C17).withOpacity(0.1), width: 2),
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
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: const Color(0xFF1C1C17).withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required bool isOn,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF1C1C17).withOpacity(0.1), width: 2),
        ),
      ),
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
                letterSpacing: -0.5,
              ),
            ),
          ),
          Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: isOn ? const Color(0xFF1B6D24) : const Color(0xFFDDDAD1),
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2,
                  right: isOn ? 2 : null,
                  left: isOn ? null : 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    color: isOn ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledItem() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E2DA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF1C1C17).withOpacity(0.1),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ENABLE DARK MODE",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1C1C17).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "SUNSTONE EDITION EXCLUSIVE",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF77574D),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          Icon(Icons.dark_mode, size: 36, color: const Color(0xFF1C1C17).withOpacity(0.2)),
        ],
      ),
    );
  }
}
