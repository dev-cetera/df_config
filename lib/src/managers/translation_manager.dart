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

/// Signature of the [TranslationManager.onError] sink.
///
/// [source] identifies where the error originated (e.g. `'tr'` for
/// `String.tr()`, `'setConfig'` for [TranslationManager.setConfig]).
typedef TranslationErrorSink = void Function(
  String source,
  Object error,
  StackTrace stack,
);

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
///
/// For life-critical applications, install an [onError] sink to be
/// notified of any internal error swallowed by `String.tr()` or any
/// other error path. Without it, failures are completely silent — which
/// is fine for non-critical UI but unacceptable when a wrong string
/// could cause patient harm.
abstract final class TranslationManager {
  //
  //
  //

  /// The currently active translation config. Reads are cheap and
  /// synchronous; writes go through [setConfig] which serialises them.
  static FileConfig get config => _active;

  /// Optional sink called when an internal error is caught (by
  /// `String.tr()` or by [setConfig]'s error-recovery path).
  ///
  /// Default is `null` — meaning errors are fully silent, matching the
  /// non-throwing contract of `tr()`. Install a sink to forward errors
  /// to your logger, telemetry, or test framework. The sink itself is
  /// wrapped in a try/catch so a buggy sink cannot in turn break the
  /// host.
  ///
  /// **Recommended for medical/safety-critical use:** set this to a
  /// strict assertion in debug builds and to your telemetry pipeline
  /// in release.
  static TranslationErrorSink? onError;

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
      reportError('setConfig', e, s);
      completer.completeError(e, s);
    }
  }

  //
  //
  //

  /// Forwards [error] to [onError] without throwing if the sink itself
  /// misbehaves. Intended for use by internals that swallow errors and
  /// want to expose them for diagnostics.
  static void reportError(String source, Object error, StackTrace stack) {
    final sink = onError;
    if (sink == null) return;
    try {
      sink(source, error, stack);
    } catch (_) {
      // A buggy sink must not break the host. Errors here are
      // intentionally swallowed — the caller's primary error has
      // already been propagated via its own mechanism.
    }
  }

  //
  //
  //

  /// Reset the active config, the write chain, and the [onError] sink.
  /// Intended for tests and for hosts that need to clear translation
  /// state between sessions (e.g. between integration runs).
  @visibleForTesting
  static void resetForTesting() {
    _active = FileConfig();
    _writeChain = Future<void>.value();
    onError = null;
  }
}
