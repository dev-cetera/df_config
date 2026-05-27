//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/src/_etc/_etc.g.dart';
import 'package:test/test.dart';

void main() {
  group('parseSourceForStringsAndComments', () {
    // ─── happy path ────────────────────────────────────────────────────

    test('returns three empty lists on empty input', () {
      final r = parseSourceForStringsAndComments('');
      expect(r.multiLineComments, isEmpty);
      expect(r.singleLineComments, isEmpty);
      expect(r.quotedStrings, isEmpty);
    });

    test('returns three empty lists on plain code', () {
      final r = parseSourceForStringsAndComments('var x = 1 + 2;');
      expect(r.multiLineComments, isEmpty);
      expect(r.singleLineComments, isEmpty);
      expect(r.quotedStrings, isEmpty);
    });

    test('captures one block comment', () {
      final r = parseSourceForStringsAndComments('/* hi */');
      expect(r.multiLineComments, ['/* hi */']);
    });

    test('captures both block comments (regression for buffer bug)', () {
      final r = parseSourceForStringsAndComments('/* a */ x /* b */');
      expect(r.multiLineComments, ['/* a */', '/* b */']);
    });

    test('captures one line comment', () {
      final r = parseSourceForStringsAndComments('// only\n');
      expect(r.singleLineComments, ['// only']);
    });

    test('captures multiple line comments', () {
      final r = parseSourceForStringsAndComments('// a\n// b\n// c');
      expect(r.singleLineComments, ['// a', '// b', '// c']);
    });

    test('captures double-quoted strings', () {
      final r = parseSourceForStringsAndComments('var s = "hello";');
      expect(r.quotedStrings, ['"hello"']);
    });

    test('captures single-quoted strings', () {
      final r = parseSourceForStringsAndComments("var s = 'hi';");
      expect(r.quotedStrings, ["'hi'"]);
    });

    test('captures escaped quotes inside strings', () {
      final r = parseSourceForStringsAndComments(r'var s = "he said \"hi\"";');
      expect(r.quotedStrings, [r'"he said \"hi\""']);
    });

    // ─── interleaving / abuse ─────────────────────────────────────────

    test('// inside a string is NOT a comment', () {
      final r = parseSourceForStringsAndComments(
        'var url = "https://example.com";',
      );
      expect(r.singleLineComments, isEmpty);
      expect(r.quotedStrings, ['"https://example.com"']);
    });

    test('*/ inside a string does not end a comment', () {
      final r = parseSourceForStringsAndComments(
        r'var s = "hi */ there"; /* real */',
      );
      expect(r.multiLineComments, ['/* real */']);
      expect(r.quotedStrings, [r'"hi */ there"']);
    });

    test('unterminated block comment swallows to EOF', () {
      final r = parseSourceForStringsAndComments('code /* never');
      expect(r.multiLineComments, ['/* never']);
    });

    test('unterminated line comment swallows to EOF', () {
      final r = parseSourceForStringsAndComments('// trailing');
      expect(r.singleLineComments, ['// trailing']);
    });

    test('unterminated quoted string swallows to EOF', () {
      final r = parseSourceForStringsAndComments('"abc');
      expect(r.quotedStrings, ['"abc']);
    });

    test('result lists are unmodifiable', () {
      final r = parseSourceForStringsAndComments('// x\n');
      expect(() => r.singleLineComments.add('bad'), throwsUnsupportedError);
      expect(() => r.multiLineComments.add('bad'), throwsUnsupportedError);
      expect(() => r.quotedStrings.add('bad'), throwsUnsupportedError);
    });

    test('1k mixed input parses without exception', () {
      final src = List.generate(
        1000,
        (i) => i % 3 == 0
            ? '/* c$i */'
            : i % 3 == 1
                ? '"s$i"'
                : '// l$i\n',
      ).join('\n');
      expect(() => parseSourceForStringsAndComments(src), returnsNormally);
    });
  });
}
