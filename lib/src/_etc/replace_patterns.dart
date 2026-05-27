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
import '_etc.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Hard cap on the input length [replacePatterns] will accept. Keeping
/// this finite prevents an attacker (or a buggy producer) from feeding a
/// multi-gigabyte string and exhausting memory. Set generously high for
/// normal use; callers can pre-validate their inputs if they need more.
const int kReplacePatternsMaxInputLength = 1 << 20; // 1 MiB

/// Hard cap on placeholders processed in a single call. Bounds the worst
/// case where every character starts a new placeholder match.
const int kReplacePatternsMaxMatches = 10000;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Replaces placeholders in [input] with values from [data], supporting
/// default values and custom delimiters via [settings].
///
/// Substitution is a *single* left-to-right pass — values inserted by the
/// pass are not themselves re-scanned. This is deliberate: re-scanning
/// would let a malicious or recursive value (e.g. `a = '{{a}}'`) loop
/// forever, and would also make the order of substitutions matter in
/// subtle ways. Callers that want multi-level resolution should pre-process
/// their data via [recursiveReplace] (which performs bounded resolution at
/// load time, not at lookup time).
@internal
String replacePatterns(
  String input,
  Map<dynamic, dynamic> data, {
  String? preferKey,
  PatternSettings settings = const PatternSettings(),
}) {
  if (input.length > kReplacePatternsMaxInputLength) {
    throw ArgumentError.value(
      input.length,
      'input.length',
      'exceeds kReplacePatternsMaxInputLength '
          '($kReplacePatternsMaxInputLength)',
    );
  }
  if (settings.opening.isEmpty || settings.closing.isEmpty) {
    // Cannot meaningfully match anything; return the input unchanged.
    return input;
  }
  final opening = RegExp.escape(settings.opening);
  final closing = RegExp.escape(settings.closing);
  final regex = RegExp(
    '$opening+(.*?)$closing+',
    multiLine: true,
    dotAll: true,
  );
  // Lazily build the lower-cased lookup map once per call when the config
  // is case-insensitive. Rebuilding it for every match would be O(n*m).
  Map<dynamic, dynamic>? loweredCache;
  Map<dynamic, dynamic> lookup() {
    if (settings.caseSensitive) return data;
    return loweredCache ??= data.map(
      (k, v) => MapEntry(k.toString().toLowerCase(), v),
    );
  }

  final out = StringBuffer();
  var cursor = 0;
  var matches = 0;
  for (final match in regex.allMatches(input)) {
    matches++;
    if (matches > kReplacePatternsMaxMatches) {
      throw StateError(
        'replacePatterns: exceeded kReplacePatternsMaxMatches '
        '($kReplacePatternsMaxMatches)',
      );
    }
    out.write(input.substring(cursor, match.start));
    final body = match.group(1)!;
    final p = getKeyAndDefaultValue(body, settings, preferKey: preferKey);
    final suggested = lookup()[p.key];
    final replacement = settings.callback?.call(
          p.key,
          suggested,
          p.defaultValue,
        ) ??
        suggested?.toString() ??
        p.defaultValue;
    out.write(replacement);
    cursor = match.end;
  }
  out.write(input.substring(cursor));
  return out.toString();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@internal
extension ReplaceAllPatternsOnStringX on String {
  /// Replaces placeholders in this string with corresponding values from a
  /// provided map, supporting default values and custom delimiters.
  @internal
  String replacePatterns(
    Map<dynamic, dynamic> data, {
    String? preferKey,
    PatternSettings settings = const PatternSettings(),
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
