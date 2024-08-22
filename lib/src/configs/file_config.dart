//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class FileConfig extends Config<ConfigFileRef> {
  //
  //
  //

  /// Creates a new [FileConfig] instance and reads its associated file.
  static Future<FileConfig> read({
    required ConfigFileRef ref,
    Map<dynamic, dynamic> fields = const {},
    ReplacePatternsSettings settings = const ReplacePatternsSettings(),
  }) async {
    final config = FileConfig(
      ref: ref,
      settings: settings,
    );
    await config.readAssociatedFile();
    return config;
  }

  //
  //
  //

  FileConfig({
    super.ref,
    super.settings,
  });

  //
  //
  //

  /// Reads and processes the associated file.
  Future<bool> readAssociatedFile() async {
    switch (ref?.type) {
      case ConfigFileType.JSON:
        await _readJsonFile();
        break;
      case ConfigFileType.JSONC:
        await _readJsoncFile();
        break;
      case ConfigFileType.YAML:
        await _readYamlFile();
        break;
      case ConfigFileType.CSV:
        await _readCsvFile();
        break;
      default:
        return false;
    }
    return true;
  }

  /// Processes a JSON file.
  Future<void> _readJsonFile() async {
    final src = await ref?.read?.call();
    if (src != null) {
      final data = jsonToData(src);
      setFields(data);
    }
  }

  /// Processes a JSONC file.
  Future<void> _readJsoncFile() async {
    var src = await ref?.read?.call();
    if (src != null) {
      final data = jsoncToData(src);
      setFields(data);
    }
  }

  /// Processes a YAML file.
  Future<void> _readYamlFile() async {
    final src = await ref?.read?.call();
    if (src != null) {
      final data = yamlToData(src);
      setFields(data);
    }
  }

  /// Processes a CSV file.
  Future<void> _readCsvFile() async {
    final src = await ref?.read?.call();
    if (src != null) {
      final data = csvToData(src, settings);
      setFields(data);
    }
  }
}
