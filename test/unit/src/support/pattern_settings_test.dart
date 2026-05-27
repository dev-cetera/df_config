//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: deprecated_member_use_from_same_package

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

void main() {
  group('PatternSettings', () {
    test('default values describe the primary `{{ … }}` syntax', () {
      const p = PatternSettings();
      expect(p.opening, '{{');
      expect(p.closing, '}}');
      expect(p.separator, '.');
      expect(p.delimiter, '||');
      expect(p.caseSensitive, isFalse);
      expect(p.callback, isNull);
    });

    test('overrides are honoured', () {
      const p = PatternSettings(
        opening: '<',
        closing: '>',
        separator: '/',
        delimiter: ';',
        caseSensitive: true,
      );
      expect(p.opening, '<');
      expect(p.closing, '>');
      expect(p.separator, '/');
      expect(p.delimiter, ';');
      expect(p.caseSensitive, isTrue);
    });
  });

  group('PatternSettings.primary', () {
    test('uses `{{ … }}` / `||` / `.`', () {
      const p = PatternSettings.primary;
      expect(p.opening, '{{');
      expect(p.closing, '}}');
      expect(p.delimiter, '||');
      expect(p.separator, '.');
      expect(p.caseSensitive, isFalse);
    });

    test('is a compile-time constant (referentially identical)', () {
      expect(
        identical(PatternSettings.primary, PatternSettings.primary),
        isTrue,
      );
    });
  });

  group('PatternSettings.secondary', () {
    test('uses `{ … }` / `|` / `.`', () {
      const p = PatternSettings.secondary;
      expect(p.opening, '{');
      expect(p.closing, '}');
      expect(p.delimiter, '|');
      expect(p.separator, '.');
      expect(p.caseSensitive, isFalse);
    });

    test('is a compile-time constant', () {
      expect(
        identical(PatternSettings.secondary, PatternSettings.secondary),
        isTrue,
      );
    });
  });

  group('Deprecated aliases (kept for backwards compatibility)', () {
    test('PrimaryPatternSettings matches PatternSettings.primary shape', () {
      const a = PrimaryPatternSettings();
      const b = PatternSettings.primary;
      expect(a.opening, b.opening);
      expect(a.closing, b.closing);
      expect(a.delimiter, b.delimiter);
      expect(a.separator, b.separator);
      expect(a.caseSensitive, b.caseSensitive);
    });

    test('SecondaryPatternSettings matches PatternSettings.secondary shape',
        () {
      const a = SecondaryPatternSettings();
      const b = PatternSettings.secondary;
      expect(a.opening, b.opening);
      expect(a.closing, b.closing);
      expect(a.delimiter, b.delimiter);
      expect(a.separator, b.separator);
      expect(a.caseSensitive, b.caseSensitive);
    });
  });
}
