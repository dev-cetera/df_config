[![pub](https://img.shields.io/pub/v/df_config.svg)](https://pub.dev/packages/df_config)
[![tag](https://img.shields.io/badge/Tag-v0.9.0-purple?logo=github)](https://github.com/dev-cetera/df_config/tree/v0.9.0)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

## Summary

`df_config` loads configuration data (YAML, JSON, JSONC, CSV) and exposes it through a tiny placeholder-substitution API. It powers `df_localization`, but is useful any time you want a config file that can reference itself and accept runtime overrides.

## What makes it interesting

A config can **reference its own values** — the resolution happens at load time, so by the time you query a key you get the fully-substituted string. Combined with runtime arg overrides, the same file works for both static defaults and dynamic templating.

```yaml
# assets/translations/en-us.yaml
app:
  name: AcmeApp
  tagline: "Welcome to {{app.name}}"      # references a sibling key
  cta: "Get started with {{app.name}} {action}"  # `{action}` is filled at call-time
```

```dart
'{{Get started||app.cta}}'.tr(args: {'action': 'now!'})
// → "Get started with AcmeApp now!"
```

### Placeholder syntax in one paragraph

- `{{ default || key }}` — primary form. Looks up `key` in the active config; if missing, returns `default`.
- `{ default | key }` — secondary form. Resolved in a second pass against `args`, so single-brace tokens are reserved for runtime values (think `{name}`).
- Keys can be **dotted paths** (`app.name`, `tags.0`) to reach into nested maps and lists.
- Lookups are **case-insensitive** by default — change via `PatternSettings(caseSensitive: true)`.

### Cross-references and templating in one example

```dart
import 'package:df_config/df_config.dart';

void main() async {
  await TranslationManager.setConfig(
    await FileConfig.read(
      ref: ConfigFileRef(
        ref: 'en',
        type: ConfigFileType.YAML,
        read: () async => '''
app:
  name: AcmeApp
  tagline: "Welcome to {{app.name}}"
  cta: "Get started with {{app.name}} {action}"
''',
      ),
    ),
  );

  print('Hi||app.tagline'.tr());
  // → "Welcome to AcmeApp"

  print('Default||app.cta'.tr(args: {'action': 'today!'}));
  // → "Get started with AcmeApp today!"

  // Unknown key → falls back to the `default` text before `||`.
  print('Just a default||missing'.tr());
  // → "Just a default"
}
```

## A larger localization example

```dart
import 'package:df_config/df_config.dart';

void main() async {
  // Create a reader for YAML translation files in `assets/translations/`.
  final reader = TranslationFileReader(
    translationsDirPath: const ['assets', 'translations'],
    fileType: ConfigFileType.YAML,
    fileReader: (filePath) async {
      // In Flutter this would be `rootBundle.loadString(filePath)`.
      return fileData[filePath] ?? '';
    },
  );

  // German.
  await reader.read('de-de');
  print('Example App||app.title'.tr());                // → "BEISPIEL!!!"

  // Spanish.
  await reader.read('es-es');
  print('Example App||app.title'.tr());                // → "EJEMPLO!!!"

  // English (with a self-reference and a runtime `{additional}` slot).
  await reader.read('en-us');
  print('Example App||app.title'.tr(
    args: {'additional': 'of the app!'},
  ));
  // → "ENGLISH X EXAMPLE!!! of the app!"

  // Unknown locale → primary pass falls back to the default text,
  // secondary pass still substitutes args.
  await reader.read('qwerty');
  print('Hey {{Example {App|app}||app.title}} dude'.tr(
    args: {'app': 'Application'},
  ));
  // → "Hey Example Application dude"
}

const fileData = {
  'assets/translations/de-de.yaml': '''
app:
  title: BEISPIEL!!!
''',
  'assets/translations/es-es.yaml': '''
app:
  title: EJEMPLO!!!
''',
  'assets/translations/en-us.yaml': '''
example: X
app:
  example: EXAMPLE
  # You can reference other keys within this file, and use {placeholders}
  # to insert values at runtime.
  title: "ENGLISH {{example}} {{app.example}}!!! {additional}"
''',
};
```

## `.tr()` always returns a String

If something inside the substitution layer throws — a buggy mapper, a pathological input, a missing config — `.tr()` returns the original string verbatim. Translation is best-effort by design; you should never see a `.tr()` call crash your UI.

## Flutter

To rebuild the widget tree when the language changes, wrap your `MaterialApp` in a `ValueListenableBuilder` (or use the convenience widgets in `df_localization`) and rebuild on every `TranslationManager.setConfig(...)` call.

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/df_config/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Raise a ticket:** Open an issue on the [GitHub repository](https://github.com/dev-cetera/df_config/issues) for questions, bugs and feature requests.
- **Get in touch:** Email [hello@robertsolves.com.au](mailto:hello@robertsolves.com.au) if you would like to contribute or collaborate.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

## 👤 Author & Contact

- Website: [robertsolves.com.au](https://robertsolves.com.au)
- Organization: [dev-cetera.com](https://dev-cetera.com)
- Email: [robert@dev-cetera.com](mailto:robert@dev-cetera.com) or [hello@robertsolves.com.au](mailto:hello@robertsolves.com.au)

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_config/main/LICENSE) for more information.
