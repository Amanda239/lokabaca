import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Helper data user yang dipakai bersama screen user dan admin.
class AuthService {
  AuthService._();

  static SupabaseClient get _db => SupabaseConfig.client;

  static User? get currentUser => _db.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static String? get currentEmail => currentUser?.email;
  static bool get isLoggedIn => currentUser != null;

  /// Ambil peran dari tabel `profiles`. Fallback ke metadata auth bila
  /// baris profil belum tersedia.
  static Future<String> currentRole() async {
    final user = currentUser;
    if (user == null) return 'user';
    try {
      final row = await _db
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = row?['role']?.toString().toLowerCase();
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {
      // Fallback di bawah.
    }
    final metadataRole = user.userMetadata?['role']?.toString().toLowerCase();
    return (metadataRole == 'admin') ? 'admin' : 'user';
  }

  static Future<bool> isAdmin() async => await currentRole() == 'admin';

  /// Profil lengkap user yang sedang login (data asli Supabase).
  static Future<Map<String, dynamic>?> currentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final row = await _db
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();
      if (row == null) return null;
      return <String, dynamic>{
        ...row,
        'email': row['email'] ?? user.email ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Simpan perubahan profil. Hanya kolom yang benar-benar ada di tabel
  /// `profiles` yang dikirim.
  static Future<void> updateProfile(Map<String, dynamic> changes) async {
    final user = currentUser;
    if (user == null) return;
    const allowed = {
      'full_name',
      'email',
      'phone',
      'avatar_url',
      'nis',
      'status',
      'birth_date',
      'gender',
    };
    final payload = <String, dynamic>{
      for (final entry in changes.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
    if (payload.isEmpty) return;
    await _db.from('profiles').update(payload).eq('id', user.id);
  }

  static Future<void> signOut() async {
    await _db.auth.signOut();
  }
}
