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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Thrown when a configuration source cannot be parsed into a key-value map.
///
/// Carries the source kind (e.g. `'json'`) and the underlying error so
/// callers can react programmatically instead of pattern-matching on a magic
/// `{'error': ...}` map.
class ConfigParseException implements Exception {
  //
  //
  //

  /// The source format that failed to parse (e.g. `'json'`, `'jsonc'`,
  /// `'yaml'`, `'csv'`).
  final String source;

  /// A short human-readable message.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  //
  //
  //

  const ConfigParseException(this.source, this.message, [this.cause]);

  //
  //
  //

  @override
  String toString() {
    final base = 'ConfigParseException($source): $message';
    return cause == null ? base : '$base [cause: $cause]';
  }
}
