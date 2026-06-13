import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';
import '../models/hero_model.dart';
import '../models/guardian_model.dart';
import 'inventory_service.dart';

/// AuthService — dùng Firebase Authentication + Cloud Firestore
///
/// Cấu trúc Firestore:
///   accounts/{uid}   → role, email, displayName
///   heroes/{uid}     → thông tin hero (con em)
///   guardians/{uid}  → thông tin guardian (phụ huynh) + danh sách heroIds
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection references ─────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get _accounts =>
      _db.collection('accounts');
  static CollectionReference<Map<String, dynamic>> get _heroes =>
      _db.collection('heroes');
  static CollectionReference<Map<String, dynamic>> get _guardians =>
      _db.collection('guardians');

  // ─── User hiện tại ─────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════════════════════
  // ĐĂNG KÝ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Đăng ký Hero (con em)
  static Future<HeroModel> registerHero({
    required String displayName,
    required String email,
    required String password,
    required String characterPath, // 'STR', 'INT', 'SPI', 'AGI'
  }) async {
    // 1. Tạo Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // 2. Tính chỉ số theo character path
    int str = 5, intVal = 5, spi = 5, agi = 5;
    switch (characterPath) {
      case 'STR':
        str = 15;
        break;
      case 'INT':
        intVal = 15;
        break;
      case 'SPI':
        spi = 15;
        break;
      case 'AGI':
        agi = 15;
        break;
    }

    final now = DateTime.now();
    final hero = HeroModel(
      uid: uid,
      displayName: displayName,
      email: email,
      characterPath: characterPath,
      level: 1,
      exp: 0,
      hp: 100,
      stamina: 100,
      mana: 100,
      strength: str,
      intellect: intVal,
      spirit: spi,
      agility: agi,
      gold: 100,
      guardianId: null,
      title: 'Novice $characterPath',
      createdAt: now,
    );

    // 3. Ghi vào Firestore dùng batch (atomic — hoặc thành công cả, hoặc rollback cả)
    final batch = _db.batch();

    batch.set(
      _accounts.doc(uid),
      AccountModel(
        uid: uid,
        email: email,
        displayName: displayName,
        role: UserRole.hero,
        createdAt: now,
      ).toMap(),
    );

    batch.set(_heroes.doc(uid), hero.toMap());

    await batch.commit();
    await InventoryService.ensureStarterInventory(hero);
    return hero;
  }

  /// Đăng ký Guardian (phụ huynh)
  static Future<GuardianModel> registerGuardian({
    required String displayName,
    required String email,
    required String password,
    required String familyTag,
  }) async {
    // 1. Tạo Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    final now = DateTime.now();

    // 2. Tạo mã mời ngẫu nhiên 6 ký tự
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final inviteCode = String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );

    final guardian = GuardianModel(
      uid: uid,
      displayName: displayName,
      email: email,
      familyTag: familyTag,
      inviteCode: inviteCode,
      heroIds: [],
      createdAt: now,
    );

    // 2. Ghi vào Firestore (batch)
    final batch = _db.batch();

    batch.set(
      _accounts.doc(uid),
      AccountModel(
        uid: uid,
        email: email,
        displayName: displayName,
        role: UserRole.guardian,
        createdAt: now,
      ).toMap(),
    );

    batch.set(_guardians.doc(uid), guardian.toMap());

    await batch.commit();
    return guardian;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ĐĂNG NHẬP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Đăng nhập, trả về AccountModel (chứa role để phân quyền màn hình)
  static Future<AccountModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // Đọc role từ Firestore
    final doc = await _accounts.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      // Tài khoản Auth tồn tại nhưng không có dữ liệu Firestore
      await _auth.signOut();
      throw Exception(
        'Dữ liệu tài khoản không tìm thấy. Vui lòng đăng ký lại.',
      );
    }

    return AccountModel.fromMap(doc.data()!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ĐĂNG XUẤT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ĐỌC DỮ LIỆU
  // ═══════════════════════════════════════════════════════════════════════════

  /// Lấy thông tin Hero
  static Future<HeroModel?> getHero(String uid) async {
    final doc = await _heroes.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return HeroModel.fromMap(doc.data()!);
  }

  /// Lắng nghe thông tin Hero theo thời gian thực
  static Stream<HeroModel?> getHeroStream(String uid) {
    return _heroes.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return HeroModel.fromMap(doc.data()!);
    });
  }

  /// Lấy thông tin Guardian
  static Future<GuardianModel?> getGuardian(String uid) async {
    final doc = await _guardians.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return GuardianModel.fromMap(doc.data()!);
  }

  /// Lấy AccountModel của user đang đăng nhập
  static Future<AccountModel?> getCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _accounts.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AccountModel.fromMap(doc.data()!);
  }

  /// Lấy danh sách Hero thuộc một Guardian
  static Future<List<HeroModel>> getHeroesOfGuardian(String guardianUid) async {
    final snapshot = await _heroes
        .where('guardianId', isEqualTo: guardianUid)
        .get();
    return snapshot.docs.map((doc) => HeroModel.fromMap(doc.data())).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS REALTIME
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream lắng nghe thay đổi Hero theo realtime
  static Stream<HeroModel?> heroStream(String uid) {
    return _heroes.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return HeroModel.fromMap(doc.data()!);
    });
  }

  /// Stream lắng nghe thay đổi Guardian theo realtime
  static Stream<GuardianModel?> guardianStream(String uid) {
    return _guardians.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GuardianModel.fromMap(doc.data()!);
    });
  }

  /// Stream lắng nghe danh sách Hero của Guardian theo realtime
  static Stream<List<HeroModel>> heroesOfGuardianStream(String guardianUid) {
    return _heroes
        .where('guardianId', isEqualTo: guardianUid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => HeroModel.fromMap(d.data())).toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIÊN KẾT HERO ↔ GUARDIAN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Liên kết một Hero với một Guardian qua mã mời
  static Future<void> linkHeroByInviteCode({
    required String heroUid,
    required String inviteCode,
  }) async {
    final querySnapshot = await _guardians
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Mã mời không hợp lệ hoặc không tồn tại.');
    }

    final guardianUid = querySnapshot.docs.first.id;

    // Liên kết Hero với Guardian tìm được
    await linkHeroToGuardian(heroUid: heroUid, guardianUid: guardianUid);
  }

  /// Liên kết một Hero với một Guardian
  static Future<void> linkHeroToGuardian({
    required String heroUid,
    required String guardianUid,
  }) async {
    final batch = _db.batch();

    // Gán guardianId cho Hero
    batch.update(_heroes.doc(heroUid), {'guardianId': guardianUid});

    // Thêm heroUid vào heroIds của Guardian
    batch.update(_guardians.doc(guardianUid), {
      'heroIds': FieldValue.arrayUnion([heroUid]),
    });

    await batch.commit();
  }

  /// Bỏ liên kết Hero khỏi Guardian
  static Future<void> unlinkHeroFromGuardian({
    required String heroUid,
    required String guardianUid,
  }) async {
    final batch = _db.batch();

    batch.update(_heroes.doc(heroUid), {'guardianId': null});

    batch.update(_guardians.doc(guardianUid), {
      'heroIds': FieldValue.arrayRemove([heroUid]),
    });

    await batch.commit();
  }

  /// Cộng (hoặc trừ) gold trực tiếp cho hero. Dùng cho phụ huynh thưởng gold.
  static Future<void> awardGold({
    required String heroUid,
    required int amount,
  }) async {
    await _heroes.doc(heroUid).update({
      'gold': FieldValue.increment(amount),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUẢN LÝ TÀI KHOẢN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Đổi tên hiển thị. Cập nhật đồng bộ ở accounts + heroes/guardians.
  static Future<void> updateDisplayName({
    required String uid,
    required UserRole role,
    required String newDisplayName,
  }) async {
    final name = newDisplayName.trim();
    if (name.isEmpty) {
      throw Exception('Tên hiển thị không được để trống.');
    }

    final batch = _db.batch();
    batch.update(_accounts.doc(uid), {'displayName': name});
    if (role == UserRole.guardian) {
      batch.update(_guardians.doc(uid), {'displayName': name});
    } else {
      batch.update(_heroes.doc(uid), {'displayName': name});
    }
    await batch.commit();
  }

  /// Đổi mật khẩu. Yêu cầu nhập lại mật khẩu hiện tại để xác thực
  /// (Firebase bắt buộc đăng nhập gần đây để đổi mật khẩu).
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // Xác thực lại danh tính trước khi đổi mật khẩu
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // XỬ LÝ LỖI
  // ═══════════════════════════════════════════════════════════════════════════

  static String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already used by another account.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại rồi thử lại thao tác này.';
      default:
        return 'Something went wrong: ${e.message}';
    }
  }
}
