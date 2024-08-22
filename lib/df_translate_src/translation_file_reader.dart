//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file located in this project's root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:path/path.dart' as p;

import '/src/_index.g.dart';
import 'translation_manager.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Provides a way to easily read translation files.
class TranslationFileReader {
  //
  //
  //

  /// A function to read a file, such as `(filePath) => File(filePath).readAsString()` or `(filePath) => rootBundle.loadString(filePath)`.
  final Future<String> Function(String filePath) fileReader;

  /// The type of the files to read.
  final ConfigFileType fileType;

  /// The directory path where the translations are stored.
  final List<String> translationsDirPath;

  //
  //
  //

  const TranslationFileReader({
    required this.fileReader,
    this.fileType = ConfigFileType.YAML,
    this.translationsDirPath = const ['translations'],
  });

  //
  //
  //

  /// Reads a locale file.
  Future<FileConfig> read(
    String localeCode, {
    String? fileName,
  }) async {
    final filePath = p.joinAll([
      ...translationsDirPath,
      fileName ?? '$localeCode.${fileType.extension}',
    ]);
    final fileConfig = FileConfig(
      ref: ConfigFileRef(
        ref: localeCode,
        type: fileType,
        read: () => fileReader(filePath),
      ),
      settings: const ReplacePatternsSettings(caseSensitive: false),
    );
    await TranslationManager().setFileConfig(fileConfig);
    return fileConfig;
  }
}
