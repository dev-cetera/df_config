<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/.github/refs/heads/main/assets/icons/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![sponsor](https://img.shields.io/badge/sponsor-grey?logo=github-sponsors)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/patreon-grey?logo=patreon)](https://www.patreon.com/c/RobertMollentze)
[![pub](https://img.shields.io/pub/v/df_config.svg)](https://pub.dev/packages/df_config)
[![tag](https://img.shields.io/badge/tag-v0.7.5-purple?logo=github)](https://github.com/dev-cetera/df_config/tree/v0.7.5)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE)

---

[![banner](https://github.com/dev-cetera/df_safer_dart/blob/v0.7.5/doc/assets/banner.png?raw=true)](https://github.com/dev-cetera)

<!-- BEGIN _README_CONTENT -->

## Summary

This package is designed to streamline loading and managing configuration data at runtime. It includes a powerful translation manager for handling multiple languages with ease, making localization straightforward. You can dynamically replace placeholders with runtime arguments and manage translations in formats like YAML, JSON, and more.

## Example

```dart
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
  print('Example App||app.title'.tr()); // prints "ENGLISH X EXAMPLE!!! additional"

  // Undefined, defaults to "Example App".
  await reader.read('qwerty');
  print(
    'Example {App;;app}||app.title'.tr(args: {'app': 'Application'}),
  );

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
```

<!-- END _README_CONTENT -->

---

☝️ Please refer to the [API reference](https://pub.dev/documentation/df_config/) for more information.

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## 🧑‍⚖️ License

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE) for more information.

