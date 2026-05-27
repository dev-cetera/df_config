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

import 'dart:async';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Process-wide owner of the **active translation [FileConfig]** that
/// `String.tr()` looks up against.
///
/// This is intentionally a static API — there is one active translation
/// per process at any time, and apps swap it when the user changes
/// locale. Writes serialise on an internal `Future` chain so two rapid
/// `setConfig` calls cannot leave the active config in an inconsistent
/// half-written state.
///
/// Typical use:
///
/// ```dart
/// await TranslationManager.setConfig(
///   FileConfig(
///     mapper: (textResult) => translations[textResult.key],
///   ),
/// );
/// 'Hello||greeting'.tr();
/// ```
abstract final class TranslationManager {
  //
  //
  //

  /// The currently active translation config. Reads are cheap and
  /// synchronous; writes go through [setConfig] which serialises them.
  static FileConfig get config => _active;

  //
  //
  //

  static FileConfig _active = FileConfig();
  static Future<void> _writeChain = Future<void>.value();

  //
  //
  //

  /// Install [fileConfig] as the active translation config.
  ///
  /// If [fileConfig] has a non-null [ConfigFileRef] with a `read`
  /// callback, the file is read first and any [ConfigParseException]
  /// propagates to the caller. Refless configs (those used purely for
  /// their `mapper` hook) are installed immediately.
  ///
  /// Concurrent calls are serialised: the *last* call to enter the
  /// chain becomes the active config when its read completes.
  static Future<FileConfig> setConfig(FileConfig fileConfig) {
    final completer = Completer<FileConfig>();
    _writeChain = _writeChain.then(
      (_) => _runOne(fileConfig, completer),
      onError: (Object _) => _runOne(fileConfig, completer),
    );
    return completer.future;
  }

  static Future<void> _runOne(
    FileConfig fileConfig,
    Completer<FileConfig> completer,
  ) async {
    try {
      await fileConfig.readAssociatedFile();
      _active = fileConfig;
      completer.complete(fileConfig);
    } catch (e, s) {
      completer.completeError(e, s);
    }
  }

  //
  //
  //

  /// Reset the active config and the write chain. Intended for tests
  /// and for hosts that need to clear translation state between
  /// sessions (e.g. between integration runs).
  @visibleForTesting
  static void resetForTesting() {
    _active = FileConfig();
    _writeChain = Future<void>.value();
  }
}
