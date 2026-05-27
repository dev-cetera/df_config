//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

FileConfig _fileConfig({
  required ConfigFileType type,
  required Future<String> Function() read,
  String tag = 'tag',
}) {
  return FileConfig(
    ref: ConfigFileRef(ref: tag, type: type, read: read),
  );
}

void main() {
  group('FileConfig.readAssociatedFile', () {
    test('returns false when ref is null', () async {
      final cfg = FileConfig();
      expect(await cfg.readAssociatedFile(), isFalse);
    });

    test('returns false when read callback is null', () async {
      final cfg = FileConfig(
        ref: const ConfigFileRef(ref: 'tag', type: ConfigFileType.YAML),
      );
      expect(await cfg.readAssociatedFile(), isFalse);
    });

    test('reads YAML and ingests fields', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.YAML,
        read: () async => 'a: 1\nb: x',
      );
      expect(await cfg.readAssociatedFile(), isTrue);
      expect(cfg.data['a'], 1);
      expect(cfg.data['b'], 'x');
    });

    test('reads JSON and ingests fields', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.JSON,
        read: () async => '{"a":1,"b":"x"}',
      );
      expect(await cfg.readAssociatedFile(), isTrue);
      expect(cfg.data['a'], 1);
    });

    test('reads JSONC and strips comments', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.JSONC,
        read: () async => '{// hi\n"a":1}',
      );
      expect(await cfg.readAssociatedFile(), isTrue);
      expect(cfg.data['a'], 1);
    });

    test('reads CSV with 2-column rows', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.CSV,
        read: () async => 'a,1\nb,2\n',
      );
      expect(await cfg.readAssociatedFile(), isTrue);
      expect(cfg.data['a'], '1');
    });

    test('propagates parse errors instead of swallowing them', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.JSON,
        read: () async => 'not-json',
      );
      await expectLater(
        cfg.readAssociatedFile(),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('propagates IO errors from the read callback', () async {
      final cfg = _fileConfig(
        type: ConfigFileType.YAML,
        read: () => Future<String>.error(StateError('boom')),
      );
      await expectLater(
        cfg.readAssociatedFile(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('FileConfig.read (static)', () {
    test('returns a populated config', () async {
      final cfg = await FileConfig.read(
        ref: ConfigFileRef(
          ref: 'tag',
          type: ConfigFileType.YAML,
          read: () async => 'k: v',
        ),
      );
      expect(cfg.data['k'], 'v');
    });

    test('passes settings through', () async {
      final cfg = await FileConfig.read(
        ref: ConfigFileRef(
          ref: 'tag',
          type: ConfigFileType.YAML,
          read: () async => 'a: x',
        ),
        settings: const SecondaryPatternSettings(),
      );
      expect(cfg.settings.opening, '{');
    });
  });

  group('FileConfig — recursive cross-references through a YAML file', () {
    test('a value can refer to another key by dotted path', () async {
      final cfg = await FileConfig.read(
        ref: ConfigFileRef(
          ref: 'tag',
          type: ConfigFileType.YAML,
          read: () async => '''
app:
  name: AcmeApp
  tagline: Welcome to {{app.name}}
''',
        ),
      );
      expect(cfg.parsedFields['app.tagline'], 'Welcome to AcmeApp');
    });

    test('chains across keys resolve at load time', () async {
      final cfg = await FileConfig.read(
        ref: ConfigFileRef(
          ref: 'tag',
          type: ConfigFileType.YAML,
          read: () async => '''
a: X
b: '{{a}}'
c: '{{b}}'
''',
        ),
      );
      expect(cfg.parsedFields['c'], 'X');
    });
  });
}
