//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';
import '/src/_etc/_etc.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension TrOnStringX on String {
  /// Translates the string using the currently active translation file.
  ///
  /// Resolves placeholders in two passes:
  ///  1. **Primary pass** uses the active config's [PatternSettings]
  ///     (default: `{{ default || key }}` syntax). The longest pattern
  ///     anchored by `{{` … `}}` is resolved against the merged
  ///     `{configFields ∪ args}` map; missing keys fall back to the
  ///     embedded default.
  ///  2. **Secondary pass** uses [secondarySettings] (default:
  ///     [PatternSettings.secondary], i.e. single braces `{ name }` /
  ///     `{ default | key }`). Intended for plain-token interpolation
  ///     inside an already-translated string, so `args` can be referenced
  ///     by short name without colliding with translation keys.
  ///
  /// Guarantees:
  ///  - Always returns a `String`. If anything throws inside (a buggy
  ///    `mapper`, a pathological input, etc.), `tr()` returns the
  ///    original input verbatim. Translation is best-effort by design —
  ///    you should never see a crash from a `.tr()` call.
  ///  - Substitution is **single-pass per layer**. A value inserted by
  ///    the primary pass is *not* re-scanned by the primary pass; the
  ///    secondary pass operates on the primary output. This prevents
  ///    infinite loops from cyclic data.
  String tr({
    Map<dynamic, dynamic> args = const {},
    String? preferKey,
    String category = '',
    PatternSettings? secondarySettings = PatternSettings.secondary,
  }) {
    try {
      return _trImpl(
        this,
        args: args,
        preferKey: preferKey,
        category: category,
        secondarySettings: secondarySettings,
      );
    } catch (_) {
      // Never let a translation failure crash the host. The original
      // string is always a safe fallback — it's what the developer
      // typed in code, so it is at minimum valid for the source locale.
      return this;
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String _trImpl(
  String self, {
  required Map<dynamic, dynamic> args,
  required String? preferKey,
  required String category,
  required PatternSettings? secondarySettings,
}) {
  final config = TranslationManager.config;
  final settings = config.settings;

  // If a category is requested, prepend it to whatever key portion the
  // input already has. We splice in `||category.` ahead of the rightmost
  // existing key so `'Hello||greet'.tr(category: 'cat')` ends up looking
  // up `cat.greet`. Inputs without a delimiter have only one part, so
  // join() leaves them alone — that is the intended no-op.
  var input = self;
  if (category.isNotEmpty) {
    final parts = input.splitByLastOccurrenceOf(settings.delimiter);
    if (parts.length == 2) {
      input = '${parts[0]}${settings.delimiter}$category${settings.separator}'
          '${parts[1]}';
    }
  }

  // Give the user-supplied mapper a chance to produce the translation
  // directly. The mapper sees the parsed `(key, defaultValue)` and may
  // return any value; we coerce to a String.
  final parsed = getKeyAndDefaultValue(input, settings, preferKey: preferKey);
  var output1 = config.mapper?.call(parsed)?.toString();

  // Primary pass: resolve `{{ … }}` style placeholders against the
  // active config + args.
  output1 ??= config.map<String>(
        input,
        args: args,
        fallback: input,
        preferKey: preferKey,
      ) ??
      input;

  if (secondarySettings == null) return output1;

  // Secondary pass: resolve `{ … }` style placeholders against the
  // primary output, again using the active config + args. The fallback
  // is the primary output, so a mismatched secondary pattern never
  // corrupts an otherwise good translation.
  return config.map<String>(
        output1,
        args: args,
        fallback: output1,
        preferKey: preferKey,
        settings: secondarySettings,
      ) ??
      output1;
}
