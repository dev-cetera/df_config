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
/// placeholders defined by the map's own key-value pairs. Supports
/// nested structures (maps and lists) and replaces placeholders in
/// strings with corresponding values.
///
/// Resolves placeholders via [JsonUtility]'s flatten/expand, then walks
/// the tree replacing only string leaves.
///
/// **Safety guards (medical/military grade):**
///  - Pre-scans [input] for **cycles** (programmatically-constructed
///    maps that contain themselves) and throws [StateError] before
///    delegating to [JsonUtility], which would otherwise infinite-loop.
///  - Enforces a [maxDepth] on the walk to bound stack usage even for
///    acyclic but pathologically-deep inputs.
Map<dynamic, dynamic> recursiveReplace(
  Map<dynamic, dynamic> input, {
  PatternSettings settings = const PatternSettings(),
  int maxDepth = 64,
}) {
  if (maxDepth <= 0) {
    throw ArgumentError.value(maxDepth, 'maxDepth', 'must be > 0');
  }
  // Belt-and-braces: refuse a cyclic input *before* JsonUtility sees
  // it. JsonUtility.flattenJson does not bound its own recursion, so
  // a cycle there would lock the process.
  _assertNoCycles(input);

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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Maximum depth [_assertNoCycles] will walk before bailing.
///
/// The cycle checker is itself recursive; for an acyclic but extremely
/// deep input it would otherwise blow the Dart stack on its own. This
/// cap is much larger than [recursiveReplace]'s default maxDepth (64)
/// so any sane input passes — pathological inputs get a clear error
/// before they can cause a crash.
const int _kAssertNoCyclesMaxDepth = 1024;

/// Throws [StateError] when [root] contains a cycle (a Map or List that
/// is reachable from itself), or when the structure is so deep that
/// walking it could exhaust the stack. Identity is tracked by
/// [identityHashCode] to handle keys/values that may have user-defined
/// `==` operators (e.g. `Equatable`) which could otherwise hide a
/// cycle.
void _assertNoCycles(Object? root) {
  final stack = <int>{};

  void visit(Object? node, int depth) {
    if (node is! Map && node is! List) return;
    if (depth > _kAssertNoCyclesMaxDepth) {
      throw StateError(
        'recursiveReplace: input depth exceeds the cycle-checker limit '
        '($_kAssertNoCyclesMaxDepth). The structure is either cyclic or '
        'pathologically deep.',
      );
    }
    final id = identityHashCode(node);
    if (stack.contains(id)) {
      throw StateError(
        'recursiveReplace: input contains a cycle; this would cause an '
        'unbounded loop inside JsonUtility.flattenJson.',
      );
    }
    stack.add(id);
    try {
      if (node is Map) {
        for (final v in node.values) {
          visit(v, depth + 1);
        }
      } else if (node is List) {
        for (final v in node) {
          visit(v, depth + 1);
        }
      }
    } finally {
      stack.remove(id);
    }
  }

  visit(root, 0);
}
