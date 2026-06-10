import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'guild_lobby_screen.dart';
import 'guild_dashboard_screen.dart';

/// Entry point cho tab GUILD.
/// Tự detect role + guildId → route đúng màn hình.
/// Dùng key để force rebuild khi cần (sau khi tạo/rời guild).
class GuildEntryScreen extends StatefulWidget {
  final VoidCallback? onOpenTasks;

  const GuildEntryScreen({super.key, this.onOpenTasks});

  @override
  State<GuildEntryScreen> createState() => _GuildEntryScreenState();
}

class _GuildEntryScreenState extends State<GuildEntryScreen> {
  bool _loading = true;
  String? _guildId;
  bool _isParent = false;
  String? _firestoreId; // doc ID trong guardians/heroes collection

  @override
  void initState() {
    super.initState();
    _resolveGuildStatus();
  }

  Future<void> _resolveGuildStatus() async {
    if (mounted) setState(() => _loading = true);

    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final db = FirebaseFirestore.instance;
    String? firestoreId;
    String role = 'hero';

    // Thử accounts/{authUid} trước (user đăng ký thực)
    final accountDoc = await db.collection('accounts').doc(authUid).get();
    if (accountDoc.exists) {
      final data = accountDoc.data()!;
      role = data['role'] as String? ?? 'hero';
      // firestoreId = authUid vì accounts dùng authUid làm doc ID
      firestoreId = authUid;
    } else {
      // Fallback: query by uid field (seed data dùng parent_3/hero_1 làm doc ID)
      final gSnap = await db
          .collection('accounts')
          .where('uid', isEqualTo: authUid)
          .limit(1)
          .get();
      if (gSnap.docs.isNotEmpty) {
        final data = gSnap.docs.first.data();
        role = data['role'] as String? ?? 'hero';
        firestoreId = gSnap.docs.first.id; // doc ID thực (e.g. parent_3)
      }
    }

    if (firestoreId == null || !mounted) {
      setState(() => _loading = false);
      return;
    }

    final isParent = role == 'guardian';
    final collection = isParent ? 'guardians' : 'heroes';
    final profileDoc = await db.collection(collection).doc(firestoreId).get();
    String? guildId = profileDoc.data()?['guildId'] as String?;
    if (guildId != null && guildId.isNotEmpty) {
      final guildDoc = await db.collection('guilds').doc(guildId).get();
      if (!guildDoc.exists) {
        await db.collection(collection).doc(firestoreId).update({
          'guildId': '',
        });
        guildId = null;
      }
    }

    if (mounted) {
      setState(() {
        _isParent = isParent;
        _firestoreId = firestoreId;
        _guildId = (guildId != null && guildId.isNotEmpty) ? guildId : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFCF9F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1C1C17)),
        ),
      );
    }

    if (_guildId != null) {
      return GuildDashboardScreen(
        guildId: _guildId!,
        isParent: _isParent,
        currentMemberId: _firestoreId,
        onLeave: _resolveGuildStatus,
        onOpenTasks: widget.onOpenTasks,
      );
    }

    return GuildLobbyScreen(
      isParent: _isParent,
      firestoreId: _firestoreId,
      onJoinedOrCreated: _resolveGuildStatus,
    );
  }
}
