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

import '../_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Replaces placeholders in a string with corresponding values from a provided
/// map, supporting default values and custom delimiters.
String replacePatterns(
  String input,
  Map<dynamic, dynamic> data, {
  String? preferKey,
  PatternSettings settings = const PrimaryPatternSettings(),
}) {
  var output = input;
  final opening = RegExp.escape(settings.opening);
  final closing = RegExp.escape(settings.closing);
  final regex = RegExp(
    '$opening+(.*?)$closing+',
    multiLine: true,
    dotAll: true,
  );
  final matches = regex.allMatches(input);
  for (final match in matches) {
    final fullMatch = match.group(0)!;
    final keyWithDefault = match.group(1)!;
    final p = getKeyAndDefaultValue(keyWithDefault, settings, preferKey: preferKey);
    final d = settings.caseSensitive
        ? data
        : data.map((k, v) => MapEntry(k.toString().toLowerCase(), v));
    final suggestedReplacementValue = d[p.key];
    final replacementValue = settings.callback
            ?.call(p.key, suggestedReplacementValue, p.defaultValue) ??
        suggestedReplacementValue?.toString() ??
        p.defaultValue;
    output = output.replaceFirst(fullMatch, replacementValue);
  }
  return output;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ReplaceAllPatternsOnStringX on String {
  /// Replaces placeholders in this string with corresponding values from a
  /// provided map, supporting default values and custom delimiters.
  String replacePatterns(
    Map<dynamic, dynamic> data, {
    String? preferKey,
    PatternSettings settings = const PrimaryPatternSettings(),
  }) {
    return _replacePatterns(
      this,
      data,
      preferKey: preferKey,
      settings: settings,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const _replacePatterns = replacePatterns;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

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
