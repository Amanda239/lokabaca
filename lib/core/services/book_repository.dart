import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Satu-satunya jalur baca data buku dari Supabase.
///
/// Semua daftar buku (beranda, kategori, pencarian, "lihat semua") memakai
/// repository ini agar batas 10 item/halaman + filter Perlakuan sama.
class BookRepository {
  BookRepository._();

  static final SupabaseClient _db = SupabaseConfig.client;
  static const int pageSize = 10;

  static const List<String> sortOptions = [
    'Terbaru',
    'Judul A-Z',
    'Rating tertinggi',
  ];

  static PostgrestFilterBuilder<PostgrestList> _base({
    String? search,
    String? category,
  }) {
    var query = _db.from('books').select();
    if (category != null && category.trim().isNotEmpty) {
      query = query.eq('category', category.trim());
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim()}%';
      query = query.or('title.ilike.$term,author.ilike.$term,category.ilike.$term');
    }
    return query;
  }

  static Future<List<Map<String, dynamic>>> fetchPage({
    int page = 0,
    String? search,
    String? category,
    String sort = 'Terbaru',
  }) async {
    final safePage = page < 0 ? 0 : page;
    final start = safePage * pageSize;
    final query = _base(search: search, category: category);
    final ordered = switch (sort) {
      'Judul A-Z' => query.order('title', ascending: true),
      'Rating tertinggi' =>
        query.order('rating', ascending: false).order('title', ascending: true),
      _ => query.order('created_at', ascending: false),
    };
    final rows = await ordered.range(start, start + pageSize - 1);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<int> count({String? search, String? category}) async {
    try {
      final rows = await _base(search: search, category: category).select('id');
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  /// Kategori asli dari database (bukan daftar hardcode).
  static Future<List<String>> categories() async {
    try {
      final rows = await _db.from('books').select('category');
      final values = <String>{};
      for (final row in rows) {
        final value = row['category']?.toString().trim();
        if (value != null && value.isNotEmpty) values.add(value);
      }
      final result = values.toList()..sort();
      return result;
    } catch (_) {
      return const <String>[];
    }
  }

  static Future<Map<String, dynamic>?> detail(int id) async {
    try {
      return await _db.from('books').select().eq('id', id).maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
