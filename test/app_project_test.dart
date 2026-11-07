import 'package:flutter_test/flutter_test.dart';
import 'package:appmaker/main.dart';

void main() {
  group('AppProject JSON', () {
    test('serializes and restores project details and entries', () {
      final original = AppProject(
        name: 'د شعرونو ټولګه',
        category: 'شعرونه',
        createdAt: '2026-11-07T10:00:00.000',
        books: [
          BookEntry(title: 'غزل', body: 'لومړی بیت\nدوهم بیت'),
          BookEntry(title: 'نظم', body: 'د نظم متن'),
        ],
      );

      final restored = AppProject.fromJson(original.toJson());

      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.createdAt, original.createdAt);
      expect(restored.books, hasLength(2));
      expect(restored.books.first.title, 'غزل');
      expect(restored.books.first.body, 'لومړی بیت\nدوهم بیت');
    });

    test('uses safe defaults for optional or missing fields', () {
      final restored = AppProject.fromJson(<String, dynamic>{});

      expect(restored.name, 'زما اپ');
      expect(restored.category, 'کتابونه');
      expect(restored.createdAt, isEmpty);
      expect(restored.books, isEmpty);
    });
  });
}
