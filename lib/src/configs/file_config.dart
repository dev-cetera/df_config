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
import '/src/_etc/_etc.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FileConfig extends Config<ConfigFileRef> {
  //
  //
  //

  FileConfig({super.ref, super.settings, super.mapper});

  //
  //
  //

  /// Reads and processes the associated file.
  ///
  /// Returns `true` if a file was read and its data ingested, `false` if
  /// there was nothing to read (e.g. the ref or reader was null, or the
  /// type is unsupported). Propagates [ConfigParseException] on malformed
  /// content and any error thrown by the [ConfigFileRef.read] callback —
  /// callers must decide whether to fall back, retry, or fail loudly.
  Future<bool> readAssociatedFile() async {
    final type = ref?.type;
    if (type == null) return false;
    final reader = ref?.read;
    if (reader == null) return false;

    final src = await reader();
    switch (type) {
      case ConfigFileType.JSON:
        setFields(jsonToData(src));
        return true;
      case ConfigFileType.JSONC:
        setFields(jsoncToData(src));
        return true;
      case ConfigFileType.YAML:
        setFields(yamlToData(src));
        return true;
      case ConfigFileType.CSV:
        setFields(csvToData(src, settings));
        return true;
    }
  }

  //
  //
  //

  /// Creates a new [FileConfig] instance and reads its associated file.
  static Future<FileConfig> read({
    required ConfigFileRef ref,
    Map<dynamic, dynamic> fields = const {},
    PatternSettings settings = const PatternSettings(),
  }) async {
    final config = FileConfig(ref: ref, settings: settings);
    await config.readAssociatedFile();
    return config;
  }
}
