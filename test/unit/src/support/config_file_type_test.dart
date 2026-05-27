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
  group('ConfigFileType', () {
    test('extensions match enum names lower-cased', () {
      expect(ConfigFileType.JSON.extension, 'json');
      expect(ConfigFileType.JSONC.extension, 'jsonc');
      expect(ConfigFileType.YAML.extension, 'yaml');
      expect(ConfigFileType.CSV.extension, 'csv');
    });

    test('values list covers all four formats', () {
      expect(ConfigFileType.values, hasLength(4));
      expect(
        ConfigFileType.values.map((e) => e.extension).toSet(),
        {'json', 'jsonc', 'yaml', 'csv'},
      );
    });

    test('extensions are unique', () {
      final exts = ConfigFileType.values.map((e) => e.extension).toList();
      expect(exts.toSet().length, exts.length);
    });
  });
}
