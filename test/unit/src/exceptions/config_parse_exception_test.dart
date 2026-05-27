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
  group('ConfigParseException', () {
    test('implements Exception', () {
      const e = ConfigParseException('json', 'msg');
      expect(e, isA<Exception>());
    });

    test('toString includes source and message', () {
      const e = ConfigParseException('yaml', 'bad shape');
      expect(e.toString(), contains('yaml'));
      expect(e.toString(), contains('bad shape'));
    });

    test('toString includes cause when present', () {
      const e = ConfigParseException('csv', 'duplicate', 'orig-cause');
      expect(e.toString(), contains('cause'));
      expect(e.toString(), contains('orig-cause'));
    });

    test('toString omits cause when absent', () {
      const e = ConfigParseException('jsonc', 'oops');
      expect(e.toString(), isNot(contains('cause')));
    });

    test('is constructible as const', () {
      const e = ConfigParseException('json', 'msg', 'cause');
      expect(e.source, 'json');
      expect(e.message, 'msg');
      expect(e.cause, 'cause');
    });
  });
}
