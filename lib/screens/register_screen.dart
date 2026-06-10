import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/main_navigation.dart';
import 'parent_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isHeroMode = true;
  String _selectedPath = 'STR'; // 'STR', 'INT', 'SPI', 'AGI'
  bool _acceptCode = false;
  bool _showPassword = false;
  bool _isLoading = false;

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _familyTagController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _familyTagController.dispose();
    super.dispose();
  }

  // Handle Registration
  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final familyTag = _familyTagController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showAlertDialog('REQUIREMENT FAILED', 'Vui lòng điền đầy đủ tên, email và mật khẩu.');
      return;
    }

    if (password.length < 6) {
      _showAlertDialog('CIPHER TOO WEAK', 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    if (!_isHeroMode && !_acceptCode) {
      _showAlertDialog('OATH UNCHECKED', 'Bạn phải đồng ý với Guardian\'s Code trước khi tiếp tục.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isHeroMode) {
        await AuthService.registerHero(
          displayName: name,
          email: email,
          password: password,
          characterPath: _selectedPath,
        );
      } else {
        await AuthService.registerGuardian(
          displayName: name,
          email: email,
          password: password,
          familyTag: familyTag,
        );
      }
      if (mounted) _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showAlertDialog('REGISTRATION FAILED', AuthService.getErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        _showAlertDialog('ERROR', 'Đã có lỗi xảy ra: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlertDialog(String title, String message) {
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
              'ACKNOWLEDGE',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFCF9F0),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFF1C1C17), width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'ACCOUNT SECURED',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF735C00),
            fontSize: 18,
          ),
        ),
        content: Text(
          'Your lineage has been officially registered in the Archives of Sunstone.',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1C1C17),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => _isHeroMode 
                      ? const MainNavigation() 
                      : const ParentNavigation(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1C17),
              foregroundColor: const Color(0xFFFCF9F0),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'BEGIN THE QUEST',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          )
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
          // Dot Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(),
            ),
          ),

          // Main Scrollable Area
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- TOP LOGO / TITLE ---
                  Text(
                    'LIFE RPG: SUNSTONE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1C1C17),
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SUNSTONE EDITION',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF77574D), // Primary brown
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- REGISTRATION FORM CARD ---
                  _buildFormCard(),

                  const SizedBox(height: 32),

                  // --- LIVE PREVIEW BOX ---
                  _buildLivePreviewBox(),

                  const SizedBox(height: 24),

                  // --- ADVANTAGE / FEATURES LIST ---
                  _buildFeaturesList(),

                  const SizedBox(height: 40),

                  // --- SCRIPTORIUM FOOTER ---
                  _buildFooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REGISTRATION FORM CARD ---
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F0),
        border: Border.all(color: const Color(0xFF1C1C17), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1C1C17),
            offset: Offset(8, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3EA), // surface-container-low
          border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        ),
        child: Stack(
          children: [
            // Decorative corners
            Positioned.fill(child: _buildCorners()),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TABS HEADER
                  _buildTabsHeader(),
                  const SizedBox(height: 28),

                  // 2. ENLIST YOUR LINEAGE TITLE
                  Text(
                    'ENLIST YOUR LINEAGE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1C1C17),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isHeroMode
                        ? 'Register as a Hero to begin your grand quest.'
                        : 'Register as a High Guardian to begin the grand quest of leadership.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4D4635),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. INPUT FIELDS
                  _buildTextField(
                    label: 'FULL NAME',
                    controller: _nameController,
                    hint: _isHeroMode ? 'e.g. Artorias the Bold' : 'e.g. Master Alistair',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    label: 'EMAIL ADDRESS',
                    controller: _emailController,
                    hint: _isHeroMode ? 'courier@kingdom.com' : 'messenger@kingdom.com',
                    icon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(),
                  const SizedBox(height: 20),

                  // FAMILY TAG (Only in Guardian Mode)
                  if (!_isHeroMode) ...[
                    _buildFamilyTagField(),
                    const SizedBox(height: 20),
                    _buildGuardianOathCheckbox(),
                    const SizedBox(height: 24),
                  ],

                  // 4. CHARACTER PATH SELECT (Only in Hero Mode)
                  if (_isHeroMode) ...[
                    _buildPathSelectorSection(),
                    const SizedBox(height: 28),
                  ],

                  // 5. SUBMIT BUTTON
                  _buildSubmitButton(),
                  const SizedBox(height: 20),

                  // 6. RETURN TO LOGIN
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'RETURN TO LOGIN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1C1C17),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF1C1C17),
                          decorationThickness: 2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TABS HEADER ---
  Widget _buildTabsHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
      ),
      height: 48,
      child: Row(
        children: [
          // HERO (CHILD) TAB
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isHeroMode = true;
                });
              },
              child: Container(
                color: _isHeroMode ? const Color(0xFF1C1C17) : Colors.white,
                alignment: Alignment.center,
                child: Text(
                  'HERO (CHILD)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: _isHeroMode ? Colors.white : const Color(0xFF7F7663),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          // BORDER DIVIDER
          Container(
            width: 3,
            color: const Color(0xFF1C1C17),
          ),
          // GUARDIAN TAB
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isHeroMode = false;
                });
              },
              child: Container(
                color: !_isHeroMode ? const Color(0xFF735C00) : Colors.white, // Olive gold/brown
                alignment: Alignment.center,
                child: Text(
                  'HIGH GUARDIAN\n(PARENT)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: !_isHeroMode ? Colors.white : const Color(0xFF7F7663),
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TEXT FIELD ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF77574D), // Primary Accent
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          color: const Color(0xFFEBE8DF), // Slightly darker cream background
          child: TextField(
            controller: controller,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C17),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFACA390),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF7F7663), size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
      ],
    );
  }

  // --- PASSWORD FIELD ---
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SECRET CIPHER',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF77574D),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          color: const Color(0xFFEBE8DF),
          child: TextField(
            controller: _passwordController,
            obscureText: !_showPassword,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C17),
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFACA390),
              ),
              prefixIcon: const Icon(Icons.key, color: Color(0xFF7F7663), size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF7F7663),
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
      ],
    );
  }

  // --- FAMILY TAG FIELD ---
  Widget _buildFamilyTagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAMILY TAG',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF77574D),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFEBE8DF),
            border: Border.all(color: const Color(0xFF1C1C17), width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hash symbol block
              Container(
                width: 48,
                color: const Color(0xFF1C1C17),
                alignment: Alignment.center,
                child: Text(
                  '#',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              // Input text field
              Expanded(
                child: TextField(
                  controller: _familyTagController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1C1C17),
                  ),
                  decoration: InputDecoration(
                    hintText: 'GOLD-LION',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFACA390),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- GUARDIAN OATH CHECKBOX ---
  Widget _buildGuardianOathCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _acceptCode = !_acceptCode;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF1C1C17), width: 2),
            ),
            child: _acceptCode
                ? const Icon(Icons.check, size: 18, color: Color(0xFF1C1C17))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I solemnly swear to uphold the Guardian\'s Code and facilitate growth through the Sunstone Archive\'s principles.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4D4635),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  // --- PATH SELECTOR GRID ---
  Widget _buildPathSelectorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOOSE YOUR CHARACTER PATH',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF77574D),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildPathCard('STR', 'STR (WARRIOR)', Icons.fitness_center),
            _buildPathCard('INT', 'INT (SCRIBE)', Icons.menu_book),
            _buildPathCard('SPI', 'SPI (MONK)', Icons.self_improvement),
            _buildPathCard('AGI', 'AGI (SCOUT)', Icons.directions_run),
          ],
        ),
      ],
    );
  }

  Widget _buildPathCard(String id, String label, IconData icon) {
    final isSelected = _selectedPath == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPath = id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCD385) : Colors.white,
          border: Border.all(
            color: const Color(0xFF1C1C17),
            width: isSelected ? 3.5 : 2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0xFF1C1C17),
                    offset: Offset(4, 4),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Color(0xFF1C1C17),
                    offset: Offset(2, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1C1C17), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1C1C17),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBMIT BUTTON ---
  Widget _buildSubmitButton() {
    final Color buttonColor = _isHeroMode ? const Color(0xFF5E5400) : const Color(0xFF705345);
    final String label = _isHeroMode ? 'CREATE HERO ACCOUNT' : 'CREATE GUARDIAN ACCOUNT';

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1C1C17),
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: Color(0xFF1C1C17), width: 3),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  // --- LIVE PREVIEW BOX ---
  Widget _buildLivePreviewBox() {
    final String label = _isHeroMode ? 'BEGIN YOUR LEGEND' : 'THE ARCHIVE OF GUARDIANS';
    
    // Grayscale photo of vintage library (Hero) / Warm historic library cathedral (Guardian)
    final String imageUrl = _isHeroMode
        ? 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&q=80&w=600'
        : 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&q=80&w=600';

    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C17),
        border: Border.all(color: const Color(0xFF1C1C17), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1C1C17),
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Grayscale filtered network image
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              _isHeroMode ? Colors.grey : Colors.amber.withOpacity(0.15),
              _isHeroMode ? BlendMode.saturation : BlendMode.colorBurn,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
            ),
          ),
          // Dark overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Top live preview small tag
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withOpacity(0.6),
                child: Text(
                  'LIVE PREVIEW: ARCHIVES OF SUNSTONE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
          // Bottom large text
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FEATURES LIST ---
  Widget _buildFeaturesList() {
    return Column(
      children: _isHeroMode
          ? [
              _buildFeatureItem(
                Icons.check_circle_outline,
                'DAILY COMMISSIONS',
                'Earn rewards for everyday real-world achievements.',
                const Color(0xFF735C00),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.emoji_events_outlined,
                'RARITY SYSTEM',
                'Collect unique titles and badges for your profile.',
                const Color(0xFF77574D),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.group_outlined,
                'GUILD SUPPORT',
                'Direct oversight from your High Guardian council.',
                const Color(0xFF5E5400),
              ),
            ]
          : [
              _buildFeatureItem(
                Icons.calendar_today_outlined,
                'ASSIGN QUESTS',
                'Transform daily chores into legendary missions.',
                const Color(0xFF735C00),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.gavel_outlined,
                'REVIEW DEEDS',
                'Validate quests and award experience points.',
                const Color(0xFF77574D),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                Icons.account_balance_outlined,
                'TREASURY MGNT',
                'Control gold flow and family allowances.',
                const Color(0xFF2E7D32),
              ),
            ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color badgeColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EA),
        border: Border.all(color: const Color(0xFF1C1C17), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF1C1C17),
            offset: Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Square icon frame
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              border: Border.all(color: const Color(0xFF1C1C17), width: 1.5),
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1C17),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7F7663),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CORNERS FOR THE FORM CONTAINER ---
  Widget _buildCorners() {
    const borderColor = Color(0xFF1C1C17);
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0,
          child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 4),
                left: BorderSide(color: borderColor, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, right: 0,
          child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 4),
                right: BorderSide(color: borderColor, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0,
          child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 4),
                left: BorderSide(color: borderColor, width: 4),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: 16, height: 16,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 4),
                right: BorderSide(color: borderColor, width: 4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- FOOTER SECTION ---
  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFD0C5AF), width: 2),
        ),
      ),
      child: Column(
        children: [
          Text(
            '© 2026 SCRIPTORIUM SYSTEMS INC.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7F7663),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF7F7663), size: 18),
              SizedBox(width: 16),
              Icon(Icons.history_edu_outlined, color: Color(0xFF7F7663), size: 18),
              SizedBox(width: 16),
              Icon(Icons.verified_user_outlined, color: Color(0xFF7F7663), size: 18),
            ],
          ),
        ],
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
