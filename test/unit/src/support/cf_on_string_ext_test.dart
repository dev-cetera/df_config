//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

void main() {
  group('CfOnStringExt.cf', () {
    late Config<ConfigRef<dynamic, dynamic>> c;
    setUp(() {
      c = Config<ConfigRef<dynamic, dynamic>>();
      c.setFields({
        'name': 'World',
        'count': '7',
        'truth': 'true',
      });
    });

    test('substitutes a known key as String', () {
      expect('Hello {{name}}'.cf<String>(c), 'Hello World');
    });

    test('converts to int when value parses', () {
      expect('{{count}}'.cf<int>(c), 7);
    });

    test('converts to bool when value parses', () {
      expect('{{truth}}'.cf<bool>(c), isTrue);
    });

    test('returns null when conversion does not match', () {
      expect('{{name}}'.cf<int>(c), isNull);
    });

    test('args override the config', () {
      expect(
        '{{name}}'.cf<String>(c, {'name': 'Override'}),
        'Override',
      );
    });

    test('falls back to default when key is missing', () {
      expect('{{Default||missing}}'.cf<String>(c), 'Default');
    });
  });
}
