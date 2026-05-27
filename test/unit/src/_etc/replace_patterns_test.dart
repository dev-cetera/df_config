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
  group('replacePatterns — single pass', () {
    test('substitutes a single placeholder', () {
      expect(
        replacePatterns('Hello {{name}}', {'name': 'World'}),
        'Hello World',
      );
    });

    test('substitutes many placeholders preserving surrounding text', () {
      expect(
        replacePatterns(
          '[a] {{x}} [b] {{y}} [c]',
          {'x': '1', 'y': '2'},
        ),
        '[a] 1 [b] 2 [c]',
      );
    });

    test('uses default when key is missing', () {
      expect(
        replacePatterns('{{Default||missing}}', const {}),
        'Default',
      );
    });

    test('case-insensitive by default', () {
      expect(replacePatterns('{{NAME}}', {'name': 'rob'}), 'rob');
    });

    test('case-sensitive setting skips mismatched case', () {
      expect(
        replacePatterns(
          '{{NAME}}',
          {'name': 'rob'},
          settings: const PatternSettings(caseSensitive: true),
        ),
        'NAME',
      );
    });

    test('preferKey overrides the embedded key', () {
      expect(
        replacePatterns(
          '{{Default||X}}',
          {'Y': 'real'},
          preferKey: 'Y',
        ),
        'real',
      );
    });

    test('null data value uses default', () {
      expect(
        replacePatterns('{{Default||x}}', {'x': null}),
        'Default',
      );
    });

    test('callback fully overrides the replacement', () {
      final s = PatternSettings(
        callback: (k, v, d) => '[CB]',
      );
      expect(
        replacePatterns('{{x}}', {'x': 'unused'}, settings: s),
        '[CB]',
      );
    });

    test('callback can fall back by returning null', () {
      final s = PatternSettings(callback: (k, v, d) => null);
      expect(
        replacePatterns(
          '{{Default||x}}',
          {'x': 'data'},
          settings: s,
        ),
        'data',
      );
    });

    test('does NOT recurse into substituted text', () {
      expect(
        replacePatterns('{{a}}', {'a': '{{b}}', 'b': 'BOOM'}),
        '{{b}}',
      );
    });

    test('self-reference does not loop', () {
      expect(replacePatterns('{{a}}', {'a': '{{a}}'}), '{{a}}');
    });

    test('multi-line via dotAll', () {
      expect(
        replacePatterns(
          '{{multi\nline||k}}',
          {'k': 'X'},
        ),
        'X',
      );
    });
  });

  group('replacePatterns — settings', () {
    test('empty opening/closing returns input unchanged', () {
      expect(
        replacePatterns(
          'hello',
          {'a': '1'},
          settings: const PatternSettings(opening: '', closing: ''),
        ),
        'hello',
      );
    });

    test('SecondaryPatternSettings uses single braces', () {
      expect(
        replacePatterns(
          '{x}',
          {'x': 'v'},
          settings: const SecondaryPatternSettings(),
        ),
        'v',
      );
    });

    test('custom delimiters', () {
      expect(
        replacePatterns(
          '<<x>>',
          {'x': 'v'},
          settings: const PatternSettings(opening: '<<', closing: '>>'),
        ),
        'v',
      );
    });

    test('case-sensitive lookup hits when case matches', () {
      expect(
        replacePatterns(
          '{{NAME}}',
          {'NAME': 'EXACT'},
          settings: const PatternSettings(caseSensitive: true),
        ),
        'EXACT',
      );
    });
  });

  group('replacePatterns — abuse', () {
    test('rejects input larger than max length', () {
      final huge = 'a' * (kReplacePatternsMaxInputLength + 1);
      expect(
        () => replacePatterns(huge, const {}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('input at the max length is still accepted', () {
      final big = 'a' * kReplacePatternsMaxInputLength;
      expect(() => replacePatterns(big, const {}), returnsNormally);
    });

    test('extension form delegates to the function', () {
      expect(
        '{{x}}'.replacePatterns({'x': 'v'}),
        'v',
      );
    });

    test('unicode pattern bodies work', () {
      expect(
        replacePatterns('{{Καλη||greeting}}', {'greeting': 'OK'}),
        'OK',
      );
    });

    test('placeholder with empty body resolves to empty default', () {
      expect(replacePatterns('A{{}}B', const {}), 'AB');
    });
  });
}
