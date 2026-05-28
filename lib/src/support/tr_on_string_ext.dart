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
  /// Translates the string using the currently active translation
  /// file.
  ///
  /// Resolves placeholders in two passes:
  ///  1. **Primary pass** uses the active config's [PatternSettings]
  ///     (default: `{{ default || key }}` syntax). Placeholders are
  ///     resolved against the merged `{configFields ∪ args}` map;
  ///     missing keys fall back to the embedded default.
  ///  2. **Secondary pass** uses [secondarySettings] (default:
  ///     [PatternSettings.secondary], i.e. single braces `{ name }` /
  ///     `{ default | key }`). Intended for plain-token interpolation
  ///     inside an already-translated string, so `args` can be
  ///     referenced by short name without colliding with translation
  ///     keys.
  ///
  /// **When to disable the secondary pass.** If your translations
  /// contain *literal* single-brace text (math, code, anything where
  /// `{x}` should not be substituted), pass `secondarySettings: null`.
  /// Without that, the secondary pass will interpret single braces in
  /// the primary output as placeholders and may strip them. For
  /// safety-critical UI strings, prefer explicit control.
  ///
  /// **RTL and unicode.** All matching is code-unit based, so Arabic,
  /// Hebrew and other RTL scripts work without special configuration.
  /// Bidi control characters (LRM, RLM, LRI, PDI, …) are passed
  /// through verbatim. If your keys use locale-sensitive characters
  /// (e.g. Turkish dotted-I, NFC vs NFD diacritics) install a custom
  /// [PatternSettings.caseFold] on your active config.
  ///
  /// **Guarantees:**
  ///  - Always returns a `String`. If anything throws inside (a
  ///    buggy `mapper`, a pathological input, a misconfigured
  ///    `PatternSettings`, etc.), `tr()` returns the original input
  ///    verbatim. Translation is best-effort by design — you should
  ///    never see a crash from a `.tr()` call.
  ///  - The swallowed error is forwarded to
  ///    [TranslationManager.onError] when a sink has been installed.
  ///    **For safety-critical applications you should install a sink**
  ///    so silent failures are observable.
  ///  - Substitution is **single-pass per layer**. A value inserted
  ///    by the primary pass is *not* re-scanned by the primary pass;
  ///    the secondary pass operates on the primary output. This
  ///    prevents infinite loops from cyclic data.
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
    } catch (e, s) {
      // Never let a translation failure crash the host. The original
      // string is always a safe fallback — it's what the developer
      // typed in code, so it is at minimum valid for the source locale.
      //
      // We still forward the error to [TranslationManager.onError] so
      // safety-critical hosts can detect a misconfiguration that would
      // otherwise be invisible. Default sink is null (silent).
      TranslationManager.reportError('tr', e, s);
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
