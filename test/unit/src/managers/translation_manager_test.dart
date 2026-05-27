//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// TranslationManager owns a process-wide static config. We reset it
// before each test so order independence is preserved.

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
  setUp(TranslationManager.resetForTesting);

  group('TranslationManager.setConfig', () {
    test('updates the static active config', () async {
      await TranslationManager.setConfig(_yaml('en', 'a: 1'));
      expect(TranslationManager.config.data['a'], 1);
    });

    test('returns the FileConfig now held by the manager', () async {
      final cfg = _yaml('en', 'a: 1');
      final stored = await TranslationManager.setConfig(cfg);
      expect(identical(stored, cfg), isTrue);
    });

    test('serialises concurrent writes — chain is not corrupted', () async {
      final futures = [
        TranslationManager.setConfig(_yaml('en', 'k: 1')),
        TranslationManager.setConfig(_yaml('fr', 'k: 2')),
        TranslationManager.setConfig(_yaml('de', 'k: 3')),
      ];
      final results = await Future.wait(futures);
      expect(results, hasLength(3));
      await TranslationManager.setConfig(_yaml('it', 'k: 4'));
      expect(TranslationManager.config.ref?.ref, 'it');
    });

    test('chain recovers after a parse failure', () async {
      final bad = FileConfig(
        ref: ConfigFileRef(
          ref: 'bad',
          type: ConfigFileType.JSON,
          read: () async => 'not-json',
        ),
      );
      await expectLater(
        TranslationManager.setConfig(bad),
        throwsA(isA<ConfigParseException>()),
      );
      // Next write must still work.
      await TranslationManager.setConfig(_yaml('en', 'k: ok'));
      expect(TranslationManager.config.ref?.ref, 'en');
    });

    test('resetForTesting clears the active config', () async {
      await TranslationManager.setConfig(_yaml('en', 'a: 1'));
      expect(TranslationManager.config.data['a'], 1);
      TranslationManager.resetForTesting();
      expect(TranslationManager.config.data, isEmpty);
      expect(TranslationManager.config.ref, isNull);
    });
  });
}
