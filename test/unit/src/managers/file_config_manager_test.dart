//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

FileConfig _yaml(String tag, String body) {
  return FileConfig(
    ref: ConfigFileRef(
      ref: tag,
      type: ConfigFileType.YAML,
      read: () async => body,
    ),
  );
}

void main() {
  group('FileConfigManager.setFileConfig', () {
    test('reads the file and registers the config', () async {
      final m = FileConfigManager();
      final cfg = _yaml('en', 'a: 1');
      final stored = await m.setFileConfig(cfg);
      expect(m.configs, contains(stored));
      expect(stored.data['a'], 1);
    });

    test('replaces existing config with the same ref', () async {
      final m = FileConfigManager();
      await m.setFileConfig(_yaml('en', 'v: old'));
      final newer = _yaml('en', 'v: new');
      await m.setFileConfig(newer);
      expect(m.configs, hasLength(1));
      expect(identical(m.configs.first, newer), isTrue);
      expect(newer.data['v'], 'new');
    });

    test('propagates parse errors from the underlying read', () async {
      final m = FileConfigManager();
      final cfg = FileConfig(
        ref: ConfigFileRef(
          ref: 'bad',
          type: ConfigFileType.JSON,
          read: () async => 'not-json',
        ),
      );
      await expectLater(
        m.setFileConfig(cfg),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('refless config (no ref) is still set; read is a no-op', () async {
      final m = FileConfigManager();
      final cfg = FileConfig();
      final stored = await m.setFileConfig(cfg);
      expect(identical(stored, cfg), isTrue);
      expect(stored.data, isEmpty);
    });
  });
}
