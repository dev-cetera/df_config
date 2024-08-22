//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file located in this project's root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_collection/df_collection.dart';

import 'replace_patterns.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Performs recursive replacement of string values within a map using
/// placeholders defined by the map's own key-value pairs. It supports nested
/// structures (maps and lists) and replaces placeholders in strings with
/// corresponding values.
Map recursiveReplace(
  Map input, {
  ReplacePatternsSettings settings = const ReplacePatternsSettings(),
}) {
  final data = expandFlattenedJson(
    flattenJson(input, separator: settings.separator),
    separator: settings.separator,
  );

  dynamic $replace<T>(dynamic inputKey, dynamic inputValue) {
    dynamic r;
    if (inputValue is Map) {
      r = {};
      for (final e in inputValue.entries) {
        final k = e.key;

        final v = e.value;
        final res = $replace(k, v);
        final localKey = '$settings.separator$k';
        data[localKey] = res;
        r[k] = res;
      }
    } else if (inputValue is List) {
      r = <dynamic>[];
      for (var n = 0; n < inputValue.length; n++) {
        final k = '$inputKey$settings.separator$n';
        final v = inputValue[n];
        final res = $replace(k, v);
        final localKey = '$settings.separator$k';
        data[localKey] = res;
        r.add(res);
      }
    } else if (inputValue is String) {
      r = replacePatterns(
        inputValue,
        data,
        settings: settings,
      );
    } else {
      r = inputValue;
    }
    return r;
  }

  final res = $replace('', input);
  return res;
}
