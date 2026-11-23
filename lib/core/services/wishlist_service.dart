import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'auth_service.dart';

/// Wishlist = daftar "ingin dibaca", disimpan di tabel `wishlists`.
/// Berbeda dengan Koleksi yang berasal dari peminjaman (`borrowings`).
class WishlistService {
  WishlistService._();

  static final SupabaseClient _db = SupabaseConfig.client;
  static final ValueNotifier<List<String>> ids = ValueNotifier(<String>[]);
  static bool _loaded = false;

  static String? get _userId => AuthService.currentUserId;

  static Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final userId = _userId;
    if (userId == null) {
      ids.value = const <String>[];
      _loaded = true;
      return;
    }
    try {
      final rows = await _db
          .from('wishlists')
          .select('book_id')
          .eq('user_id', userId);
      ids.value = rows
          .map((row) => row['book_id']?.toString())
          .whereType<String>()
          .toList();
    } catch (_) {
      ids.value = const <String>[];
    }
    _loaded = true;
  }

  static bool isFavorite(Map<String, dynamic> book) {
    final id = book['id']?.toString();
    return id != null && ids.value.contains(id);
  }

  static Future<void> toggle(Map<String, dynamic> book) async {
    final id = book['id']?.toString();
    final userId = _userId;
    if (id == null || userId == null) return;

    final has = ids.value.contains(id);
    // Optimistic UI.
    ids.value = has
        ? ids.value.where((item) => item != id).toList()
        : [...ids.value, id];

    try {
      if (has) {
        await _db
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('book_id', id);
      } else {
        await _db.from('wishlists').insert({
          'user_id': userId,
          'book_id': int.tryParse(id) ?? id,
        });
      }
    } catch (_) {
      // Kembalikan bila gagal.
      ids.value = has ? [...ids.value, id] : ids.value.where((e) => e != id).toList();
    }
  }

  static Future<void> remove(String bookId) async {
    final userId = _userId;
    if (userId == null) return;
    ids.value = ids.value.where((item) => item != bookId).toList();
    try {
      await _db
          .from('wishlists')
          .delete()
          .eq('user_id', userId)
          .eq('book_id', bookId);
    } catch (_) {}
  }

  /// Buku-buku wishlist milik user yang sedang login (data asli Supabase).
  static Future<List<Map<String, dynamic>>> books() async {
    final userId = _userId;
    if (userId == null) return const <Map<String, dynamic>>[];
    try {
      final rows = await _db
          .from('wishlists')
          .select('book_id, books(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final result = <Map<String, dynamic>>[];
      for (final row in rows) {
        final book = row['books'];
        if (book is Map) {
          result.add(Map<String, dynamic>.from(book));
        } else if (book is List && book.isNotEmpty) {
          result.add(Map<String, dynamic>.from(book.first as Map));
        }
      }
      if (result.isEmpty && ids.value.isNotEmpty) {
        final fallback = await _db
            .from('books')
            .select()
            .inFilter('id', ids.value.map<dynamic>((e) => int.tryParse(e) ?? e).toList());
        return fallback
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      return result;
    } catch (_) {
      try {
        final fallback = await _db
            .from('books')
            .select()
            .inFilter('id', ids.value.map<dynamic>((e) => int.tryParse(e) ?? e).toList());
        return fallback
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      } catch (_) {
        return const <Map<String, dynamic>>[];
      }
    }
  }
}
