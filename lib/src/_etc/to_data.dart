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
/// that do *not* satisfy `Map<String, dynamic>` checks deeper than the root.
/// We deeply convert the tree to plain `Map<String, dynamic>` /
/// `List<dynamic>` so downstream code can rely on standard types.
@internal
Map<String, dynamic> yamlToData(String src) {
  Object? decoded;
  try {
    decoded = loadYaml(src);
  } catch (e) {
    throw ConfigParseException('yaml', 'Failed to load YAML.', e);
  }
  final plain = _yamlToPlain(decoded);
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
/// Each row is interpreted as `[k0, k1, ..., value]`, with leading columns
/// joined by [PatternSettings.separator] to form a single dotted key.
/// Rows with fewer than 2 columns are skipped silently. Duplicate keys
/// cause [ConfigParseException] — life-critical configs should not silently
/// drop entries.
@internal
Map<String, dynamic> csvToData(
  String src, [
  PatternSettings settings = const PatternSettings(),
]) {
  Map<int, List<String>> csv;
  try {
    csv = CsvUtility.i.csvToMap(src);
  } catch (e) {
    throw ConfigParseException('csv', 'Failed to parse CSV.', e);
  }
  final out = <String, dynamic>{};
  for (final row in csv.values) {
    if (row.length < 2) continue;
    final key = row.length == 2
        ? row[0]
        : row.sublist(0, row.length - 1).join(settings.separator);
    final value = row.last;
    if (out.containsKey(key)) {
      throw ConfigParseException('csv', 'Duplicate key in CSV: "$key".');
    }
    out[key] = value;
  }
  return out;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Recursively converts a YAML decoder result into plain Dart collections.
/// Scalar leaves are left as-is.
Object? _yamlToPlain(Object? input) {
  if (input is Map) {
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      out[e.key.toString()] = _yamlToPlain(e.value);
    }
    return out;
  }
  if (input is List) {
    return List<dynamic>.generate(
      input.length,
      (i) => _yamlToPlain(input[i]),
      growable: false,
    );
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
