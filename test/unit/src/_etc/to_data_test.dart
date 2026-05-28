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
  group('jsonToData', () {
    test('decodes a flat object', () {
      expect(jsonToData('{"a":1,"b":"x"}'), {'a': 1, 'b': 'x'});
    });

    test('decodes a nested object preserving structure', () {
      final r = jsonToData('{"a":{"b":1}}');
      expect(r['a'], {'b': 1});
    });

    test('throws ConfigParseException on malformed JSON', () {
      expect(
        () => jsonToData('{not-json'),
        throwsA(
          isA<ConfigParseException>().having((e) => e.source, 'source', 'json'),
        ),
      );
    });

    test('throws ConfigParseException when top-level is an array', () {
      expect(
        () => jsonToData('[1,2,3]'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('throws ConfigParseException when top-level is a scalar', () {
      expect(
        () => jsonToData('42'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('empty object decodes to empty map', () {
      expect(jsonToData('{}'), isEmpty);
    });
  });

  group('jsoncToData', () {
    test('strips // line comments', () {
      expect(
        jsoncToData('{"a":1 // trailing\n,"b":2}'),
        {'a': 1, 'b': 2},
      );
    });

    test('strips /* */ block comments', () {
      expect(jsoncToData('{/* hi */"a":1}'), {'a': 1});
    });

    test('preserves // inside a string', () {
      expect(
        jsoncToData('{"url":"https://example.com"}'),
        {'url': 'https://example.com'},
      );
    });

    test('preserves /* */ inside a string', () {
      expect(
        jsoncToData(r'{"msg":"hi /* not a comment */ there"}'),
        {'msg': 'hi /* not a comment */ there'},
      );
    });

    test('throws ConfigParseException with source=jsonc', () {
      expect(
        () => jsoncToData('{not-jsonc'),
        throwsA(
          isA<ConfigParseException>()
              .having((e) => e.source, 'source', 'jsonc'),
        ),
      );
    });

    test('unterminated block comment is tolerated by the stripper', () {
      // The stripper eats everything to EOF; the result is invalid
      // JSON so jsonDecode throws and we surface that as a parse error.
      expect(
        () => jsoncToData('/* never closed'),
        throwsA(isA<ConfigParseException>()),
      );
    });
  });

  group('yamlToData', () {
    test('decodes a simple mapping', () {
      expect(yamlToData('a: 1\nb: x'), {'a': 1, 'b': 'x'});
    });

    test('deep-converts YamlMap/YamlList to plain Map<String,dynamic>/List',
        () {
      final r = yamlToData('''
people:
  - name: Ada
  - name: Bob
''');
      final people = r['people'];
      expect(people, isA<List<dynamic>>());
      expect((people as List).first, isA<Map<String, dynamic>>());
      expect(people.first['name'], 'Ada');
    });

    test('throws when top-level is a scalar', () {
      expect(
        () => yamlToData('just a string'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('throws when top-level is a sequence', () {
      expect(
        () => yamlToData('- a\n- b'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('handles unicode keys and values', () {
      final r = yamlToData('Καλη: μέρα');
      expect(r['Καλη'], 'μέρα');
    });
  });

  group('csvToData', () {
    test('2-column rows become key/value pairs', () {
      expect(csvToData('a,1\nb,2\n'), {'a': '1', 'b': '2'});
    });

    test('joins leading columns with separator for >2-column rows', () {
      expect(
        csvToData('a,b,1\nc,d,2\n'),
        {'a.b': '1', 'c.d': '2'},
      );
    });

    test('honours custom separator from PatternSettings', () {
      expect(
        csvToData(
          'a,b,1\n',
          const PatternSettings(separator: ':'),
        ),
        {'a:b': '1'},
      );
    });

    test('rows with fewer than 2 columns are skipped', () {
      expect(csvToData('lone\na,1\n'), {'a': '1'});
    });

    test('throws on duplicate key (no silent overwrite)', () {
      expect(
        () => csvToData('a,1\na,2\n'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('throws ConfigParseException on parse failure', () {
      // CsvUtility is robust; force a duplicate to confirm the exception
      // type and source field.
      expect(
        () => csvToData('a,1\na,2'),
        throwsA(
          isA<ConfigParseException>().having((e) => e.source, 'source', 'csv'),
        ),
      );
    });
  });
}
