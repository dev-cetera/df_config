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
  group('ConfigRef', () {
    test('defaults: ref=null, type=null', () {
      const r = ConfigRef<String, int>();
      expect(r.ref, isNull);
      expect(r.type, isNull);
    });

    test('values are exposed verbatim', () {
      const r = ConfigRef<String, int>(ref: 'k', type: 42);
      expect(r.ref, 'k');
      expect(r.type, 42);
    });

    test('equal when both ref and type match', () {
      const a = ConfigRef<String, int>(ref: 'k', type: 42);
      const b = ConfigRef<String, int>(ref: 'k', type: 42);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when ref differs', () {
      const a = ConfigRef<String, int>(ref: 'k', type: 42);
      const b = ConfigRef<String, int>(ref: 'x', type: 42);
      expect(a, isNot(equals(b)));
    });

    test('not equal when type differs', () {
      const a = ConfigRef<String, int>(ref: 'k', type: 42);
      const b = ConfigRef<String, int>(ref: 'k', type: 1);
      expect(a, isNot(equals(b)));
    });

    test('two null-valued refs are equal', () {
      const a = ConfigRef<String, int>();
      const b = ConfigRef<String, int>();
      expect(a, equals(b));
    });
  });
}
