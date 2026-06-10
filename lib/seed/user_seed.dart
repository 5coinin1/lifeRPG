// ignore_for_file: avoid_print

/// User demo seed was removed.
///
/// The old seed created:
/// - guardians: parent_3, parent_4, parent_5
/// - heroes: hero_1 through hero_7
///
/// Keep this class as a no-op so run_seed.dart can still compile.
class UserSeed {
  static Future<void> seedUsersToFirestore() async {
    print('User seed skipped: demo parents/heroes were removed.');
  }
}
