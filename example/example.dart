//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:df_config/df_translate.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// NOTE TO FLUTTER DEVELOPERS:
// To use this in Flutter, you need to refresh the widget tree after
// changing the language. You can do this by wrapping your MaterialApp in a
// ValueListenable and using a ValueNotifier, or any other method that
// rebuilds the widget tree when the language changes.

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() async {
  // Create a reader that reads a YAML files.
  final reader = TranslationFileReader(
    // Specify the directory paths where the translation files are located,
    // e.g. assets/translations/en-us.yaml.
    translationsDirPath: ['assets', 'translations'],
    // You can also choose ConfigFileType.JSON, ConfigFileType.JSONC or
    // ConfigFileType.CSV.
    fileType: ConfigFileType.YAML,
    fileReader: (filePath) async {
      print(filePath);
      // Read the file here and return its contents.
      final contents = fileData[filePath] ?? '';
      return contents;
    },
  );

  // German.
  await reader.read('de-de');
  print('Example App||app.title'.tr()); // prints "BEISPIEL!!"

  // Spanish.
  await reader.read('es-es');
  print('Example App||app.title'.tr()); // prints "EJEMPLO!!"

  // English.
  await reader.read('en-us');
  print(
    'Example App||app.title'.tr(),
  ); // prints "ENGLISH X EXAMPLE!!! additional"

  // Undefined, defaults to "Example Application".
  await reader.read('qwerty');
  print('Example {App;;app}||app.title'.tr(args: {'app': 'Application'}));

  // You can also pass custom arguments to the translation.
  await reader.read('en-us');
  print(
    'This is the <<<Example||app.title>>>'.tr(
      args: {
        // Replace {additional} in the translation with 'of the app!'.
        'additional': 'of the app!',
      },
    ),
  ); // prints "This is the ENGLISH X EXAMPLE!!! of the app!"
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final fileData = {
  'assets/translations/de-de.yaml': YAML_FILE_DATA_DE_DE,
  'assets/translations/es-es.yaml': YAML_FILE_DATA_ES_ES,
  'assets/translations/en-us.yaml': YAML_FILE_DATA_EN_US,
};

const YAML_FILE_DATA_ES_ES = '''
app:
  title: EJEMPLO!!!
''';

const YAML_FILE_DATA_DE_DE = '''
app:
  title: BEISPIEL!!!
''';

const YAML_FILE_DATA_EN_US = '''
example: X
app:
  example: EXAMPLE
  # You can reference other translations within this file, and use placeholders
  # to insert values during runtime.
  title: ENGLISH <<<example>>> <<<app.example>>>!!! {additional}
''';
