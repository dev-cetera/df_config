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

/// Converts raw JSON [src] to a key-value map.
///
/// Throws [ConfigParseException] on malformed JSON or a non-map root.
@internal
Map<String, dynamic> jsonToData(String src) {
  Object? decoded;
  try {
    decoded = jsonDecode(src);
  } catch (e) {
    throw ConfigParseException('json', 'Failed to decode JSON.', e);
  }
  final map = letMapOrNull<String, dynamic>(decoded);
  if (map == null) {
    throw ConfigParseException(
      'json',
      'Top-level JSON value must be an object, got ${decoded.runtimeType}.',
    );
  }
  return map;
}

/// Converts raw JSONC [src] to a key-value map.
///
/// Strips `//` and `/* */` comments before decoding. Quoted strings are
/// preserved verbatim so a `//` *inside* a string does not confuse the
/// stripper. Throws [ConfigParseException] on malformed JSONC.
@internal
Map<String, dynamic> jsoncToData(String src) {
  final stripped = _stripJsoncComments(src);
  Object? decoded;
  try {
    decoded = jsonDecode(stripped);
  } catch (e) {
    throw ConfigParseException('jsonc', 'Failed to decode JSONC.', e);
  }
  final map = letMapOrNull<String, dynamic>(decoded);
  if (map == null) {
    throw ConfigParseException(
      'jsonc',
      'Top-level JSONC value must be an object, got ${decoded.runtimeType}.',
    );
  }
  return map;
}

/// Converts raw YAML [src] to a key-value map.
///
/// `loadYaml` from `package:yaml` returns `YamlMap` / `YamlList` wrappers
/// that do *not* satisfy `Map<String, dynamic>` checks deeper than the
/// root. We deeply convert the tree to plain `Map<String, dynamic>` /
/// `List<dynamic>` so downstream code can rely on standard types.
///
/// **Safety guards:**
///  - YAML can carry cycles via anchors and aliases (`&a [1, *a]`). A
///    naive recursive conversion would stack-overflow on such input;
///    [_yamlToPlain] detects revisits and throws
///    [ConfigParseException].
///  - Non-string YAML keys that collide after stringification (e.g. an
///    integer `1` and a string `"1"`) cause a [ConfigParseException]
///    rather than silently overwriting one of them.
@internal
Map<String, dynamic> yamlToData(String src) {
  Object? decoded;
  try {
    decoded = loadYaml(src);
  } catch (e) {
    throw ConfigParseException('yaml', 'Failed to load YAML.', e);
  }
  final plain = _yamlToPlain(decoded, _PlainConverterState());
  final map = letMapOrNull<String, dynamic>(plain);
  if (map == null) {
    throw ConfigParseException(
      'yaml',
      'Top-level YAML value must be a mapping, got ${decoded.runtimeType}.',
    );
  }
  return map;
}

/// Converts raw CSV [src] to a key-value map.
///
/// Each row is interpreted as `[k0, k1, ..., value]`, with leading
/// columns joined by [PatternSettings.separator] to form a single dotted
/// key. Duplicate keys cause [ConfigParseException] — life-critical
/// configs should not silently drop entries.
///
/// **Strict mode.** By default rows with fewer than 2 columns are
/// skipped silently (compat with non-critical use). Pass
/// `strict: true` to instead throw [ConfigParseException] for any
/// malformed row — the recommended setting for medical and military
/// applications where a quietly-dropped translation could change the
/// meaning of a UI.
@internal
Map<String, dynamic> csvToData(
  String src, [
  PatternSettings settings = const PatternSettings(),
  bool strict = false,
]) {
  Map<int, List<String>> csv;
  try {
    csv = CsvUtility.i.csvToMap(src);
  } catch (e) {
    throw ConfigParseException('csv', 'Failed to parse CSV.', e);
  }
  final out = <String, dynamic>{};
  for (final entry in csv.entries) {
    final row = entry.value;
    if (row.length < 2) {
      if (strict) {
        throw ConfigParseException(
          'csv',
          'Row ${entry.key} has only ${row.length} column(s); '
              'need at least 2 (key and value).',
        );
      }
      continue;
    }
    final key = row.length == 2
        ? row[0]
        : row.sublist(0, row.length - 1).join(settings.separator);
    final value = row.last;
    if (out.containsKey(key)) {
      throw ConfigParseException(
        'csv',
        'Duplicate key "$key" in CSV (row ${entry.key}).',
      );
    }
    out[key] = value;
  }
  return out;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Mutable bookkeeping used by [_yamlToPlain] to detect cycles and
/// stringification key collisions without lugging extra parameters.
class _PlainConverterState {
  final Set<int> visiting = <int>{};
  // Hard cap on recursion depth as an extra belt-and-braces guard. The
  // visited set should already prevent infinite loops, but pathological
  // (very deep, acyclic) inputs are also worth bounding.
  static const int maxDepth = 1024;
  int depth = 0;
}

/// Recursively converts a YAML decoder result into plain Dart
/// collections, with cycle detection and key-collision checks.
Object? _yamlToPlain(Object? input, _PlainConverterState state) {
  if (input is Map) {
    final id = identityHashCode(input);
    if (state.visiting.contains(id)) {
      throw const ConfigParseException(
        'yaml',
        'Cyclic structure detected (YAML anchor/alias loop).',
      );
    }
    if (state.depth >= _PlainConverterState.maxDepth) {
      throw const ConfigParseException(
        'yaml',
        'YAML depth exceeded safety limit.',
      );
    }
    state.visiting.add(id);
    state.depth++;
    try {
      final out = <String, dynamic>{};
      for (final e in input.entries) {
        final key = e.key?.toString() ?? 'null';
        if (out.containsKey(key)) {
          throw ConfigParseException(
            'yaml',
            'Duplicate key after stringification: "$key" '
                '(two distinct YAML keys collide on toString()).',
          );
        }
        out[key] = _yamlToPlain(e.value, state);
      }
      return out;
    } finally {
      state.visiting.remove(id);
      state.depth--;
    }
  }
  if (input is List) {
    final id = identityHashCode(input);
    if (state.visiting.contains(id)) {
      throw const ConfigParseException(
        'yaml',
        'Cyclic structure detected (YAML anchor/alias loop).',
      );
    }
    if (state.depth >= _PlainConverterState.maxDepth) {
      throw const ConfigParseException(
        'yaml',
        'YAML depth exceeded safety limit.',
      );
    }
    state.visiting.add(id);
    state.depth++;
    try {
      return List<dynamic>.generate(
        input.length,
        (i) => _yamlToPlain(input[i], state),
        growable: false,
      );
    } finally {
      state.visiting.remove(id);
      state.depth--;
    }
  }
  return input;
}

/// Strips JSONC comments (`//` line and `/* */` block) without touching
/// content inside quoted strings.
String _stripJsoncComments(String src) {
  final buf = StringBuffer();
  final n = src.length;
  var i = 0;
  while (i < n) {
    final ch = src[i];
    // Inside a quoted string: copy verbatim, honouring `\` escapes.
    if (ch == '"' || ch == "'") {
      final quote = ch;
      buf.write(ch);
      i++;
      while (i < n) {
        final c = src[i];
        buf.write(c);
        if (c == r'\' && i + 1 < n) {
          buf.write(src[i + 1]);
          i += 2;
          continue;
        }
        i++;
        if (c == quote) break;
      }
      continue;
    }
    // Block comment.
    if (ch == '/' && i + 1 < n && src[i + 1] == '*') {
      final end = src.indexOf('*/', i + 2);
      i = end == -1 ? n : end + 2;
      continue;
    }
    // Line comment.
    if (ch == '/' && i + 1 < n && src[i + 1] == '/') {
      final end = src.indexOf('\n', i + 2);
      i = end == -1 ? n : end;
      continue;
    }
    buf.write(ch);
    i++;
  }
  return buf.toString();
}
