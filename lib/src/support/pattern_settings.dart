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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// How df_config recognises a placeholder in a string.
///
/// A placeholder is bounded by [opening] and [closing] and contains a
/// `default <delimiter> key` body, where [delimiter] separates the
/// fallback text from the lookup key. [separator] joins the parts of a
/// dotted key (`user.profile.name`).
///
/// **Case-folding** applies to keys (never to the default value, which
/// is returned verbatim). When [caseSensitive] is false the lookup key
/// is passed through [caseFold] — by default `String.toLowerCase`. For
/// Turkish/Azerbaijani or other locales where the Unicode default
/// lowering produces the wrong result, supply a locale-aware folder.
/// `caseFold` is also a natural place to hang Unicode normalisation
/// (NFC) or bidirectional-control-character stripping for RTL scripts.
///
/// **Direction-agnostic.** All matching operates on UTF-16 code units,
/// not on visual order. Arabic, Hebrew, Persian and Urdu content works
/// out of the box; the only practical concern is making sure your keys
/// are byte-for-byte stable (no stray bidi-control characters, no
/// inconsistent precomposed-vs-combining diacritics).
///
/// Two canonical configurations are provided as constants:
///  - [primary] — `{{ default || key }}` with `.` separator.
///  - [secondary] — `{ default | key }` with `.` separator.
///
/// `tr()` runs both passes by default: primary against translations,
/// secondary against ad-hoc args.
class PatternSettings {
  final String opening;
  final String closing;
  final String separator;
  final String delimiter;
  final bool caseSensitive;

  /// User-supplied callback invoked for every successful pattern match.
  /// Receives the parsed key, the value from the lookup map (or null if
  /// not present), and the parsed default value. Return the desired
  /// replacement, or `null` to fall back to the standard
  /// `value ?? default` chain.
  final String? Function(
    String key,
    dynamic suggestedReplacementValue,
    String defaultValue,
  )? callback;

  /// Optional custom case-folding function. Used in place of
  /// `String.toLowerCase` when [caseSensitive] is false. Pass a
  /// locale-aware folder here for Turkish (`İ` ↔ `i`), Azerbaijani, or
  /// other special locales — and/or chain in Unicode normalisation
  /// (NFC) and bidi-control stripping for RTL languages.
  ///
  /// When null and [caseSensitive] is false, `String.toLowerCase` is
  /// used.
  final String Function(String input)? caseFold;

  const PatternSettings({
    this.opening = '{{',
    this.closing = '}}',
    this.separator = '.',
    this.delimiter = '||',
    this.caseSensitive = false,
    this.callback,
    this.caseFold,
  });

  /// Applies the active case-folding strategy to [input].
  ///
  /// - When [caseSensitive] is true, returns [input] unchanged.
  /// - When [caseSensitive] is false and [caseFold] is provided, uses
  ///   that callback. The callback is wrapped — if it throws, this
  ///   method falls back to `input.toLowerCase()` so a buggy folder
  ///   cannot break translation lookups.
  /// - Otherwise, returns `input.toLowerCase()`.
  String foldKey(String input) {
    if (caseSensitive) return input;
    final fold = caseFold;
    if (fold != null) {
      try {
        return fold(input);
      } catch (_) {
        // Defensive fallback. A safety-critical host should install
        // [TranslationManager.onError] to be notified of this path.
        return input.toLowerCase();
      }
    }
    return input.toLowerCase();
  }

  /// The primary placeholder syntax: `{{ default || key }}`.
  static const PatternSettings primary = PatternSettings();

  /// The secondary placeholder syntax: `{ default | key }`. Used by
  /// `tr()` for the second pass so args can be interpolated with
  /// single braces without colliding with translation keys.
  static const PatternSettings secondary = PatternSettings(
    opening: '{',
    closing: '}',
    delimiter: '|',
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Deprecated alias for [PatternSettings.primary].
///
/// Kept so existing code compiles. New code should prefer the constant.
@Deprecated('Use PatternSettings.primary or const PatternSettings() instead.')
final class PrimaryPatternSettings extends PatternSettings {
  const PrimaryPatternSettings({super.callback});
}

/// Deprecated alias for [PatternSettings.secondary].
///
/// Kept so existing code compiles. New code should prefer the constant.
@Deprecated('Use PatternSettings.secondary instead.')
final class SecondaryPatternSettings extends PatternSettings {
  const SecondaryPatternSettings({super.callback})
      : super(
          opening: '{',
          closing: '}',
          delimiter: '|',
        );
}
