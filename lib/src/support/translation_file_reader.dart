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

/// Convenience for loading translation files from disk or asset bundles.
class TranslationFileReader {
  //
  //
  //

  /// A function to read a file. Typical implementations:
  /// `(filePath) => File(filePath).readAsString()` on dart:io, or
  /// `(filePath) => rootBundle.loadString(filePath)` on Flutter.
  final TFileReaderFunction? fileReader;

  /// The type of the files to read.
  final ConfigFileType fileType;

  /// The directory path segments where the translation files live.
  /// Joined with [path.joinAll], so callers can stay platform-agnostic.
  final List<String> translationsDirPath;

  /// Optional hook for custom key resolution. See [Config.mapper].
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

  /// Reads a locale file and registers it with the active
  /// [TranslationManager]. Returns the loaded [FileConfig].
  ///
  /// [fileReader] (parameter) overrides the instance-level [fileReader]
  /// for this single call. If both are null, this throws [StateError] —
  /// the previous `assert`-based check was a debug-mode-only guard and
  /// would have produced a confusing NPE in release builds.
  Future<FileConfig> read(
    String languageTag, {
    String? fileName,
    TFileReaderFunction? fileReader,
  }) async {
    final effectiveReader = fileReader ?? this.fileReader;
    if (effectiveReader == null) {
      throw StateError(
        'TranslationFileReader.read: no fileReader provided. Pass one to '
        'the constructor or to read() directly.',
      );
    }
    if (languageTag.isEmpty && (fileName == null || fileName.isEmpty)) {
      throw ArgumentError.value(
        languageTag,
        'languageTag',
        'languageTag must be non-empty when fileName is not provided.',
      );
    }
    final filePath = joinAll([
      ...translationsDirPath,
      fileName ?? '$languageTag.${fileType.extension}',
    ]);
    final fileConfig = FileConfig(
      ref: ConfigFileRef(
        ref: languageTag,
        type: fileType,
        read: () => effectiveReader(filePath),
      ),
      settings: const PatternSettings(),
      mapper: mapper,
    );
    return TranslationManager.setConfig(fileConfig);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TFileReaderFunction = Future<String> Function(String filePath);
