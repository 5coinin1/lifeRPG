import 'package:flutter/material.dart';
import '../services/guild_service.dart';

/// Form tạo guild - chỉ dành cho Guardian (phụ huynh).
class CreateGuildScreen extends StatefulWidget {
  final String guardianId;

  const CreateGuildScreen({super.key, required this.guardianId});

  @override
  State<CreateGuildScreen> createState() => _CreateGuildScreenState();
}

class _CreateGuildScreenState extends State<CreateGuildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  String _selectedIcon = 'shield';
  bool _loading = false;

  static const _icons = [
    ('shield', Icons.shield, 'Shield'),
    ('book', Icons.menu_book, 'Lore'),
    ('local_florist', Icons.local_florist, 'Nature'),
    ('bolt', Icons.bolt, 'Lightning'),
    ('star', Icons.star, 'Star'),
    ('fire', Icons.local_fire_department, 'Fire'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final guildId = await GuildService().createGuild(
        ownerId: widget.guardianId,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        iconName: _selectedIcon,
        tag: _tagCtrl.text.trim(),
      );

      if (mounted) {
        // Cập nhật guildId cho guardian hiện tại (đã làm trong service)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guild "${_nameCtrl.text}" created! ID: $guildId'),
            backgroundColor: const Color(0xFF388E3C),
          ),
        );
        Navigator.pop(context, true); // trả về true để Lobby refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFBA1A1A)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C17),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('FORGE YOUR GUILD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFED65B), letterSpacing: 1)),
        shape: const Border(bottom: BorderSide(color: Color(0xFFFED65B), width: 2)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Guild Icon selector ────────────────────────────────────────
            const _SectionLabel('CHOOSE GUILD EMBLEM'),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final (key, iconData, label) = _icons[i];
                  final selected = _selectedIcon == key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = key),
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF1C1C17) : const Color(0xFFEBE8DF),
                        border: Border.all(color: selected ? const Color(0xFFFED65B) : const Color(0xFF1C1C17), width: 2),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(iconData, color: selected ? const Color(0xFFFED65B) : const Color(0xFF7F7663), size: 28),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: selected ? Colors.white : const Color(0xFF7F7663))),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Guild name ────────────────────────────────────────────────
            const _SectionLabel('GUILD NAME'),
            const SizedBox(height: 8),
            _buildField(
              controller: _nameCtrl,
              hint: 'e.g. The Scribes of Aether',
              validator: (v) => (v == null || v.trim().length < 3) ? 'Tên cần ít nhất 3 ký tự' : null,
            ),
            const SizedBox(height: 20),

            // ── Tag ───────────────────────────────────────────────────────
            const _SectionLabel('GUILD TAG / MOTTO'),
            const SizedBox(height: 8),
            _buildField(
              controller: _tagCtrl,
              hint: 'e.g. Scholarly / Active Now',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
            ),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────────
            const _SectionLabel('GUILD DESCRIPTION'),
            const SizedBox(height: 8),
            _buildField(
              controller: _descCtrl,
              hint: 'Mô tả guild của bạn...',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().length < 10) ? 'Mô tả cần ít nhất 10 ký tự' : null,
            ),
            const SizedBox(height: 32),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C17),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF4D4635),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('⚔  FORGE GUILD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              '* Bạn sẽ là Guild Master. Các thành viên cần được bạn phê duyệt để tham gia.',
              style: TextStyle(fontSize: 11, color: Color(0xFF7F7663)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C17)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7F7663), fontWeight: FontWeight.normal),
        filled: true,
        fillColor: const Color(0xFFEBE8DF),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF1C1C17), width: 2)),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFF4D4635), width: 1)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: Color(0xFFBA1A1A), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F7663), letterSpacing: 1.5),
      );
}
