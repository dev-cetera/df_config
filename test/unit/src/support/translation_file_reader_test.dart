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
  setUp(TranslationManager.resetForTesting);

  group('TranslationFileReader — construction', () {
    test('default fileType is YAML', () {
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileReader: (_) async => 'x: 1',
      );
      expect(r.fileType, ConfigFileType.YAML);
    });
  });

  group('TranslationFileReader.read', () {
    test('builds posix <tag>.<extension> when no fileName is given', () async {
      String? capturedPath;
      final r = TranslationFileReader(
        translationsDirPath: const ['root', 'tr'],
        fileType: ConfigFileType.YAML,
        fileReader: (p) async {
          capturedPath = p;
          return 'a: 1';
        },
      );
      await r.read('en');
      // Always posix — Flutter rootBundle requires forward slashes on
      // every platform, including Windows.
      expect(capturedPath, 'root/tr/en.yaml');
    });

    test('uses fileName when provided (posix-joined)', () async {
      String? capturedPath;
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileType: ConfigFileType.YAML,
        fileReader: (p) async {
          capturedPath = p;
          return 'a: 1';
        },
      );
      await r.read('en', fileName: 'custom.yml');
      expect(capturedPath, 'root/custom.yml');
    });

    test('per-call fileReader overrides instance fileReader', () async {
      var hitDefault = false;
      var hitOverride = false;
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileType: ConfigFileType.YAML,
        fileReader: (_) async {
          hitDefault = true;
          return 'a: 1';
        },
      );
      await r.read(
        'en',
        fileReader: (_) async {
          hitOverride = true;
          return 'a: 1';
        },
      );
      expect(hitOverride, isTrue);
      expect(hitDefault, isFalse);
    });

    test('throws StateError when no fileReader is configured', () async {
      const r = TranslationFileReader(
        translationsDirPath: ['root'],
        fileReader: null,
      );
      await expectLater(r.read('en'), throwsA(isA<StateError>()));
    });

    test('throws ArgumentError on empty tag with no fileName', () async {
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileReader: (_) async => 'a: 1',
      );
      await expectLater(r.read(''), throwsA(isA<ArgumentError>()));
    });

    test('parse errors surface to the caller', () async {
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileType: ConfigFileType.JSON,
        fileReader: (_) async => 'not-json',
      );
      await expectLater(
        r.read('en'),
        throwsA(isA<ConfigParseException>()),
      );
    });

    test('registers the config with TranslationManager', () async {
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileReader: (_) async => 'k: v',
      );
      await r.read('en');
      expect(TranslationManager.config.data['k'], 'v');
    });

    test('mapper is forwarded into the produced FileConfig', () async {
      final r = TranslationFileReader(
        translationsDirPath: const ['root'],
        fileReader: (_) async => 'k: v',
        mapper: (textResult) => 'M(${textResult.key})',
      );
      final cfg = await r.read('en');
      expect(cfg.mapper, isNotNull);
    });
  });
}
