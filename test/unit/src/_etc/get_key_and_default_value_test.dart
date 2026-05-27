//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:df_config/src/_etc/_etc.g.dart';
import 'package:test/test.dart';

void main() {
  group('getKeyAndDefaultValue', () {
    // ─── happy path ────────────────────────────────────────────────────

    test('parses default||key', () {
      final r = getKeyAndDefaultValue(
        'Hello||world',
        const PrimaryPatternSettings(),
      );
      expect(r.defaultValue, 'Hello');
      expect(r.key, 'world');
    });

    test('lower-cases key by default', () {
      final r = getKeyAndDefaultValue(
        'X||WORLD',
        const PrimaryPatternSettings(),
      );
      expect(r.key, 'world');
    });

    test('preserves key case when caseSensitive: true', () {
      final r = getKeyAndDefaultValue(
        'X||WORLD',
        const PatternSettings(caseSensitive: true),
      );
      expect(r.key, 'WORLD');
    });

    test('uses input as both fields when no delimiter', () {
      final r = getKeyAndDefaultValue(
        'standalone',
        const PrimaryPatternSettings(),
      );
      expect(r.key, 'standalone');
      expect(r.defaultValue, 'standalone');
    });

    test('preferKey wins over parsed key', () {
      final r = getKeyAndDefaultValue(
        'X||y',
        const PrimaryPatternSettings(),
        preferKey: 'FORCED',
      );
      expect(r.key, 'forced');
      expect(r.defaultValue, 'X');
    });

    test('preferKey wins over caseSensitive too', () {
      final r = getKeyAndDefaultValue(
        'X||y',
        const PatternSettings(caseSensitive: true),
        preferKey: 'FORCED',
      );
      expect(r.key, 'FORCED');
    });

    test('custom delimiter is respected', () {
      final r = getKeyAndDefaultValue(
        'a;;b',
        const PatternSettings(delimiter: ';;'),
      );
      expect(r.defaultValue, 'a');
      expect(r.key, 'b');
    });

    test('splits on LAST delimiter occurrence (left-side may contain it)',
        () {
      final r = getKeyAndDefaultValue(
        'a||b||c',
        const PrimaryPatternSettings(),
      );
      expect(r.defaultValue, 'a||b');
      expect(r.key, 'c');
    });

    // ─── edges & abuse ────────────────────────────────────────────────

    test('empty input is handled', () {
      final r = getKeyAndDefaultValue('', const PrimaryPatternSettings());
      expect(r.defaultValue, '');
      expect(r.key, '');
    });

    test('leading delimiter: empty default, key on the right', () {
      final r = getKeyAndDefaultValue(
        '||key',
        const PrimaryPatternSettings(),
      );
      expect(r.defaultValue, '');
      expect(r.key, 'key');
    });

    test('trailing delimiter: default on the left, empty key', () {
      final r = getKeyAndDefaultValue(
        'default||',
        const PrimaryPatternSettings(),
      );
      expect(r.defaultValue, 'default');
      expect(r.key, '');
    });

    test('throws on empty delimiter', () {
      expect(
        () => getKeyAndDefaultValue('x', const PatternSettings(delimiter: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unicode in key and default is preserved', () {
      final r = getKeyAndDefaultValue(
        'Καλημέρα||greeting',
        const PrimaryPatternSettings(),
      );
      expect(r.defaultValue, 'Καλημέρα');
      expect(r.key, 'greeting');
    });

    test('huge input does not crash', () {
      final big = 'x' * 100000;
      final r =
          getKeyAndDefaultValue('$big||k', const PrimaryPatternSettings());
      expect(r.defaultValue.length, 100000);
      expect(r.key, 'k');
    });
  });
}
