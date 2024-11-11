//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

//import 'package:df_config/df_config.dart';
import 'dart:io';

import 'package:df_config/df_translate.dart';
import 'package:test/test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  group(1, () {
    test('Testing reader', () async {
      final reader = TranslationFileReader(
        translationsDirPath: ['_tests', 'translations'],
        fileReader: (filePath) {
          final file = File(filePath);
          final content = file.readAsString();
          return content;
        },
      );
      final content = await reader.read('en_au');
      expect('AU', content.data['country']);
    });

    test('Testing reader', () async {
      final reader = TranslationFileReader(
        translationsDirPath: ['_tests', 'translations'],
        fileReader: (filePath) {
          final file = File(filePath);
          final content = file.readAsString();
          return content;
        },
      );
      final content = await reader.read('en_au');
      final manager = TranslationManager();
      await manager.setFileConfig(content);

      expect('AU', 'country'.tr());
      expect('AU', 'TEST||country'.tr());
      expect(
        'AU',
        '{TEST}||country'.tr(
          args: {
            'TEST': '123',
          },
        ),
      );
      expect(
        '123',
        '{TEST}'.tr(
          args: {
            'TEST': '123',
          },
        ),
      );
    });
  });
}
