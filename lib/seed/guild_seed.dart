// ignore_for_file: avoid_print

/// Guild demo seed was removed because it depended on removed demo users:
/// parent_3, parent_4, parent_5 and hero_1 through hero_7.
///
/// Keep this class as a no-op so run_seed.dart can still compile.
class GuildSeed {
  static Future<void> seedGuildsToFirestore() async {
    print('Guild seed skipped: demo guild data was removed.');
  }
}
