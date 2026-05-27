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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Splits an `input` of the form `default||key` (using
/// [PatternSettings.delimiter]) into a `(key, defaultValue)` pair.
///
/// - If [input] contains no delimiter, the whole string is used for both
///   the key and the default value.
/// - [preferKey], when provided, always wins over any key implied by the
///   input.
/// - The key is lower-cased unless [PatternSettings.caseSensitive] is
///   true. The default value is returned verbatim.
///
/// The function never returns `null` fields — empty strings are
/// substituted when no signal is available, and an [ArgumentError] is
/// thrown if the delimiter is empty (which would otherwise produce
/// ambiguous splits).
@internal
TGetKeyAndDefaultValueResult getKeyAndDefaultValue(
  String input,
  PatternSettings settings, {
  String? preferKey,
}) {
  if (settings.delimiter.isEmpty) {
    throw ArgumentError.value(
      settings.delimiter,
      'settings.delimiter',
      'must be non-empty',
    );
  }
  final parts = input.splitByLastOccurrenceOf(settings.delimiter);
  final left = parts.isNotEmpty ? parts[0] : '';
  final right = parts.length > 1 ? parts[1] : null;
  final defaultValue = left;
  var key = preferKey ?? right ?? left;
  if (!settings.caseSensitive) {
    key = key.toLowerCase();
  }
  return (key: key, defaultValue: defaultValue);
}

typedef TGetKeyAndDefaultValueResult = ({String key, String defaultValue});
