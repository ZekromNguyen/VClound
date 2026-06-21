/// Environment configuration.
///
/// Values are read from `--dart-define` flags. Sensible defaults
/// are kept so `flutter run` works without arguments locally,
/// but production builds should always pass explicit defines.
///
/// Examples:
///   flutter run \
///     --dart-define=VCLOUD_SUPABASE_URL=https://... \
///     --dart-define=VCLOUD_SUPABASE_ANON_KEY=...
class Env {
  Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'VCLOUD_SUPABASE_URL',
    defaultValue: 'https://ccjldpmsvzxudqjemtkw.supabase.co',
  );

  /// Client-side anon (publishable) key. Safe to ship in binary.
  /// RLS policies are the security boundary, not this key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'VCLOUD_SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_9Pxl6uZ5KAHSR21noY9G4A_MTZVSoWi',
  );
}
