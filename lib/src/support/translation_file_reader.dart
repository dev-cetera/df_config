//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';
import '/src/_etc/_etc.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Provides a way to easily read translation files.
class TranslationFileReader {
  //
  //
  //

  /// A function to read a file, such as `(filePath) => File(filePath).readAsString()` or `(filePath) => rootBundle.loadString(filePath)`.
  final TFileReaderFunction? fileReader;

  /// The type of the files to read.
  final ConfigFileType fileType;

  /// The directory path where the translations are stored.
  final List<String> translationsDirPath;

  /// Specify to manually map the translation keys.
  final dynamic Function(TGetKeyAndDefaultValueResult textResult)? mapper;

  //
  //
  //

  const TranslationFileReader({
    this.fileType = ConfigFileType.YAML,
    required this.fileReader,
    required this.translationsDirPath,
    this.mapper,
  });

  //
  //
  //

  const TranslationFileReader.withDefaultAssetsPackagePath({
    this.fileReader,
    this.fileType = ConfigFileType.YAML,
    this.mapper,
  }) : translationsDirPath = const [
         'assets',
         'packages',
         'assets',
         'assets',
         'translations',
       ];

  //
  //
  //

  /// Reads a locale file.
  Future<FileConfig> read(
    String languageTag, {
    String? fileName,
    TFileReaderFunction? fileReader,
  }) async {
    final fileReader1 = fileReader ?? this.fileReader;
    assert(fileReader1 != null, 'A file reader function must be provided.');
    final filePath = joinAll([
      ...translationsDirPath,
      fileName ?? '$languageTag.${fileType.extension}',
    ]);
    final fileConfig = FileConfig(
      ref: ConfigFileRef(
        ref: languageTag,
        type: fileType,
        read: () => fileReader1!(filePath),
      ),
      settings: const PrimaryPatternSettings(),
      mapper: mapper,
    );
    await TranslationManager().setFileConfig(fileConfig);
    return fileConfig;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TFileReaderFunction = Future<String> Function(String filePath);
