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
}

final class PrimaryPatternSettings extends PatternSettings {
  const PrimaryPatternSettings({super.callback})
      : super(
          opening: '{{',
          closing: '}}',
          separator: '.',
          delimiter: '||',
          caseSensitive: false,
        );
}

final class SecondaryPatternSettings extends PatternSettings {
  const SecondaryPatternSettings({super.callback})
      : super(
          opening: '{',
          closing: '}',
          separator: '.',
          delimiter: '|',
          caseSensitive: false,
        );
}
