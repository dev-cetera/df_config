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

/// Performs recursive replacement of string values within a map using
/// placeholders defined by the map's own key-value pairs. Supports nested
/// structures (maps and lists) and replaces placeholders in strings with
/// corresponding values.
///
/// Resolves placeholders via [JsonUtility]'s flatten/expand, then walks the
/// tree replacing only string leaves. A maximum recursion depth guards
/// against runaway structures.
Map<dynamic, dynamic> recursiveReplace(
  Map<dynamic, dynamic> input, {
  PatternSettings settings = const PatternSettings(),
  int maxDepth = 64,
}) {
  if (maxDepth <= 0) {
    throw ArgumentError.value(maxDepth, 'maxDepth', 'must be > 0');
  }
  final sep = settings.separator;
  final data = JsonUtility.i.expandFlattenedJson(
    JsonUtility.i.flattenJson(
      input.mapKeys((e) => e.toString()),
      separator: sep,
    ),
    separator: sep,
  );

  dynamic walk(String path, dynamic value, int depth) {
    if (depth > maxDepth) {
      throw StateError(
        'recursiveReplace exceeded maxDepth ($maxDepth) at path "$path"',
      );
    }
    if (value is Map) {
      final out = <dynamic, dynamic>{};
      for (final e in value.entries) {
        final k = e.key;
        final childPath = path.isEmpty ? '$k' : '$path$sep$k';
        final replaced = walk(childPath, e.value, depth + 1);
        data[childPath] = replaced;
        out[k] = replaced;
      }
      return out;
    }
    if (value is List) {
      final out = <dynamic>[];
      for (var n = 0; n < value.length; n++) {
        final childPath = path.isEmpty ? '$n' : '$path$sep$n';
        final replaced = walk(childPath, value[n], depth + 1);
        data[childPath] = replaced;
        out.add(replaced);
      }
      return out;
    }
    if (value is String) {
      return replacePatterns(value, data, settings: settings);
    }
    return value;
  }

  final result = walk('', input, 0);
  return result as Map<dynamic, dynamic>;
}
