import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home_screen.dart';
import '../screens/guild_entry_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/map_screen.dart';
import '../screens/hero_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Default to Quests (HomeScreen)

  // Danh sách các màn hình chính
  List<Widget> get _screens => [
    const HeroScreen(),
    const HomeScreen(), // Quests
    GuildEntryScreen(onOpenTasks: () => _onItemTapped(1)), // Guild
    const ShopScreen(), // Shop
    const MapScreen(), // Map
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF6F3EA),
          border: Border(top: BorderSide(color: Color(0xFF1C1C17), width: 2)),
        ),
        child: Row(
          children: [
            _buildNavItem(0, 'HERO', Icons.person),
            _buildNavItem(
              1,
              'QUESTS',
              Icons.hardware,
            ), // Dùng hardware vì giống 2 công cụ chéo nhau
            _buildNavItem(2, 'GUILD', Icons.groups),
            _buildNavItem(3, 'SHOP', Icons.payments),
            _buildNavItem(4, 'MAP', Icons.map_outlined),
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
