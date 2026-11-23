import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi terpusat untuk Supabase.
///
/// Semua screen sebaiknya memakai [client] melalui helper ini supaya satu
/// instance yang sama dipakai di seluruh aplikasi (user & admin).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://mwcjntpvfxyvfosxjwrk.supabase.co';
  static const String publishableKey =
      'sb_publishable_doU8rB3Cj8DdO02xDzXSCg_2-9yhE_q';

  static const String bookCoversBucket = 'book-covers';
  static const String avatarsBucket = 'profile-avatars';

  static SupabaseClient get client => Supabase.instance.client;
}
