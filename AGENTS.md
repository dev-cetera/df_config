# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The workspace-level `../../CLAUDE.md` covers the umbrella layout, cross-package wiring, PowerShell `@scripts/`, lint baseline, and release flow — read it for anything not specific to this package. Notes below cover only what's particular to `df_config`.

## Purpose

Runtime config loader + lightweight translation engine. Reads YAML / JSON / JSONC / CSV into a flat map and resolves `{{key}}` / `{{default||key}}` placeholders against that map, with support for runtime args and a second pass of secondary syntax (`{key}`).

## Architecture

The class graph is small and layered. Read it before editing — many files have only a few methods that pivot on this shape:

```
Config<TConfigRef>            ── parses fields, resolves patterns via map<T>()
   └─ FileConfig              ── adds readAssociatedFile() (json/jsonc/yaml/csv)

ConfigManager<TConfig>        ── holds a Set<TConfig>, dedupes by ref
   └─ FileConfigManager       ── triggers readAssociatedFile() on insert
        └─ TranslationManager ── also writes the most-recent FileConfig to
                                 the static `TranslationManager.config`,
                                 which `String.tr()` reads globally

ConfigRef<TRef, TType>        ── equality key for Configs
   └─ ConfigFileRef           ── adds a `read: Future<String> Function()?`

TranslationFileReader         ── convenience: joins translationsDirPath +
                                 "$languageTag.${fileType.extension}",
                                 builds a FileConfig, hands it to
                                 TranslationManager().setFileConfig(...)
```

Important consequences:

- **`TranslationManager.config` is a process-global static.** Calling `reader.read('de-de')` mutates it; the next `'x'.tr()` anywhere in the process picks up the new language. Tests that call `.tr()` are order-sensitive — beware of leakage between tests.
- **`tr()` runs the input through `Config.map` twice** when `secondarySettings` is non-null (its default): once with `PrimaryPatternSettings` (`{{ }}`, `||`), then again with `SecondaryPatternSettings` (`{ }`, `|`). This is how `{{Greeting||hello}} {name}` lets `hello` come from translations while `name` comes from the `args:` map passed at call time. If you change pattern semantics, change both passes consistently.
- **`Config.map` auto-wraps the input** in `opening`/`closing` if neither is present (`config.dart:115`). That's why a bare key like `'TEST||country'` works — it's treated as if the user wrote `{{TEST||country}}`. Don't "fix" this; tests depend on it.
- **`setFields()` runs `recursiveReplace` then `JsonUtility.i.expandJson`** to flatten nested maps via the configured `separator` (default `.`). So a YAML like `app: { title: X }` becomes accessible as both nested lookup and dotted key `app.title`.

## Pattern syntax

The `default||key` form (delimiter from `PatternSettings.delimiter`) is parsed by `getKeyAndDefaultValue` (`lib/src/_etc/get_key_and_default_value.dart`). Rules:

- `Hello||world` → key=`world`, default=`Hello`.
- `Hello` (no delimiter) → key=`Hello`, default=`Hello`.
- `preferKey:` arg overrides the key half but not the default.
- `caseSensitive: false` (the default) lowercases the key and the lookup map.

When in doubt about a bug in placeholder resolution, walk through `replacePatterns` (`lib/src/_etc/replace_patterns.dart`) — it's a single regex pass that delegates to `getKeyAndDefaultValue` per match. The `settings.callback` hook fires per match and can override the resolved value; it's the extension point for missing-translation logging etc.

## Internal helpers

Everything in `lib/src/_etc/` is annotated `@internal`. These are exported through the package barrel for tests but consumers shouldn't import them — when adding new helpers there, keep the `@internal` annotation.

## Public exports

Two libraries are intended for consumers:

- `package:df_config/df_config.dart` — main barrel via the generated `src/_src.g.dart`.
- The README also references `package:df_config/df_translate.dart`, but **that entry point does not currently exist as a separate file** — the `.tr()` extension ships from the main barrel via `support/tr_on_string_ext.dart`. Either add the file or update the README; don't silently rely on the import working.

## Tests

Layout differs from `df_safer_dart` — there is no `test/unit/...` tree. Just two flat files plus a fixtures directory:

- `test/pattern_settings_test.dart` — pure unit tests for `getKeyAndDefaultValue`.
- `test/translations_test/translations_test.dart` — integration test that reads real YAML from `test/translations_test/translations/` via `dart:io`. The path constant `defaultTranslationsDirPath = ['test', 'translations_test', 'translations']` assumes the test is run from the package root — `dart test` from elsewhere will silently fail to find the files.

When adding integration-style tests, put fixtures under `test/<group>_test/<fixtures>/` and follow the same `dart:io` pattern.

## Generated files

- `lib/src/_src.g.dart` and `lib/src/_etc/_etc.g.dart` are generated by `df_generate_dart_indexes`. Don't hand-edit. After adding a new file under `lib/src/<dir>/`, regenerate rather than appending an `export` manually.

## Release

This package uses the standard workspace release flow (`pub.dev_package_workflow`) plus an extra `deploy.sh` at the package root:

```sh
./deploy.sh   # checks out prod, merges main, pushes — triggers .github/workflows/prod.yml
```

`prod.yml` is the actual pub.dev publish trigger; merging to `prod` is the gate. Don't push directly to `prod` from a feature branch.

Before any manual `dart pub publish`, run `pwsh ../../@scripts/delete_all_pubspec_overrides.ps1` from the workspace root — `pubspec_overrides.yaml` overrides `df_string`/`df_type`/`df_collection` to local paths, and publish will fail if those are present (or worse, publish a broken artifact).

## Gotchas

- `Config.parsedFields` and `Config.data` are both `late final` initialized in the constructor — calling `setFields` multiple times mutates the same maps via `clear()` + `addAll()`. The `late final` is misleading; don't refactor it to immutable without auditing callers.
- The `mapper` callback on `Config` / `TranslationFileReader` runs *before* placeholder replacement and short-circuits it when it returns non-null. Use it for full-key overrides; use `PatternSettings.callback` for per-placeholder overrides.
- `TranslationManager` extends `FileConfigManager` extends `ConfigManager<TConfig>` (raw `TConfig` — no type argument). That's intentional but means `FileConfigManager.configs` is `Set<dynamic>`-ish at the type system level; don't add type-narrowing assertions that assume `FileConfig`.
