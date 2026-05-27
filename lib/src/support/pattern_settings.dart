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
/// dotted key (`user.profile.name`) and [caseSensitive] decides whether
/// the lookup is case-aware.
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
  final String? Function(
    String key,
    dynamic suggestedReplacementValue,
    String defaultValue,
  )? callback;

  const PatternSettings({
    this.opening = '{{',
    this.closing = '}}',
    this.separator = '.',
    this.delimiter = '||',
    this.caseSensitive = false,
    this.callback,
  });

  /// The primary placeholder syntax: `{{ default || key }}`.
  static const PatternSettings primary = PatternSettings();

  /// The secondary placeholder syntax: `{ default | key }`. Used by
  /// `tr()` for the second pass so args can be interpolated with single
  /// braces without colliding with translation keys.
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
