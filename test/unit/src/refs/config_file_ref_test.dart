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
  group('ConfigFileRef', () {
    test('default type is YAML', () {
      const r = ConfigFileRef();
      expect(r.type, ConfigFileType.YAML);
    });

    test('ref and read callback are exposed', () async {
      Future<String> read() async => 'hi';
      final r = ConfigFileRef(ref: 'en', read: read);
      expect(r.ref, 'en');
      expect(await r.read!(), 'hi');
    });

    test('equality includes ref and type but ignores the read closure', () {
      // Closures don't compare structurally, so this also confirms the
      // Equatable props inherited from ConfigRef do *not* incorporate
      // the read callback.
      final a = ConfigFileRef(
        ref: 'en',
        type: ConfigFileType.JSON,
        read: () async => 'a',
      );
      final b = ConfigFileRef(
        ref: 'en',
        type: ConfigFileType.JSON,
        read: () async => 'b',
      );
      expect(a, equals(b));
    });

    test('different types make refs unequal', () {
      const a = ConfigFileRef(ref: 'en', type: ConfigFileType.JSON);
      const b = ConfigFileRef(ref: 'en', type: ConfigFileType.YAML);
      expect(a, isNot(equals(b)));
    });
  });
}
