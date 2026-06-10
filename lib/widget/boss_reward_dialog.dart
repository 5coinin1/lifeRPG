import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/equipment_model.dart';
import '../services/game_data_service.dart';

/// Bảng chúc mừng tiêu diệt boss + danh sách phần thưởng.
/// Dùng chung cho màn boss raid (defeat ngay) và home (đăng nhập sau).
Future<void> showBossRewardDialog(
  BuildContext context, {
  required String bossName,
  required List<String> rewards,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFCF9F0),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF1C1C17), width: 3),
        borderRadius: BorderRadius.zero,
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            'BOSS DEFEATED!',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1C1C17),
            ),
          ),
          if (bossName.isNotEmpty)
            Text(
              bossName,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF77574D),
              ),
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'REWARDS',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF7F7663),
            ),
          ),
          const SizedBox(height: 12),
          if (rewards.isEmpty)
            Text(
              'No loot dropped this time.\nBut the guild still slayed the boss!',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: const Color(0xFF7F7663),
              ),
            )
          else
            _RewardList(rewardIds: rewards),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C1C17),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Text(
            'AWESOME!',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class _RewardList extends StatelessWidget {
  const _RewardList({required this.rewardIds});

  final List<String> rewardIds;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EquipmentModel?>>(
      future: Future.wait(rewardIds.map(GameDataService.getEquipment)),
      builder: (context, snapshot) {
        final items = snapshot.data;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rewardIds.length, (i) {
            final item = items != null && i < items.length ? items[i] : null;
            final name = item?.name ?? rewardIds[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3EA),
                border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
              ),
              child: Row(
                children: [
                  if (item != null && item.imageUrl.isNotEmpty)
                    Image.network(
                      item.imageUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.inventory_2_outlined,
                        size: 28,
                        color: Color(0xFF77574D),
                      ),
                    )
                  else
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 28,
                      color: Color(0xFF77574D),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1C1C17),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
