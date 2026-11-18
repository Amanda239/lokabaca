
import 'package:flutter/material.dart';

class WishlistStore {
  static final ValueNotifier<List<Map<String, dynamic>>> books =
      ValueNotifier([]);

  static bool isFavorite(Map<String, dynamic> book) {
    return books.value.any((item) => _sameBook(item, book));
  }

  static bool _sameBook(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstId = first['id'];
    final secondId = second['id'];

    if (firstId != null && secondId != null) {
      return firstId.toString() == secondId.toString();
    }

    return first['title']?.toString() ==
        second['title']?.toString();
  }

  static void toggle(Map<String, dynamic> book) {
    final updatedBooks = List<Map<String, dynamic>>.from(
      books.value,
    );

    final index = updatedBooks.indexWhere(
      (item) => _sameBook(item, book),
    );

    if (index >= 0) {
      updatedBooks.removeAt(index);
    } else {
      updatedBooks.add(Map<String, dynamic>.from(book));
    }

    books.value = updatedBooks;
  }
}
