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

/// In-memory registry of [Config] instances, keyed by their [ConfigRef].
///
/// A config is considered "the same" as another iff their refs are equal —
/// the underlying data is intentionally not part of the identity, so a
/// fresh read of the same file replaces the previous entry instead of
/// duplicating it.
class ConfigManager<TConfig extends Config<ConfigRef<dynamic, dynamic>>> {
  //
  //
  //

  final configs = <TConfig>{};

  //
  //
  //

  ConfigManager(Set<TConfig> configs) {
    this.configs.addAll(configs);
  }

  //
  //
  //

  /// Registers [config], replacing any existing entry with an equal [ref].
  ///
  /// Returns the [config] now held by the manager (either the newly stored
  /// one or, if there was no change, the previously stored equivalent).
  TConfig setConfig(TConfig config) {
    final existing = configs.firstWhereOrNull((e) => e.ref == config.ref);
    if (existing != null) {
      if (identical(existing, config)) return existing;
      configs.remove(existing);
    }
    configs.add(config);
    return config;
  }

  //
  //
  //

  /// Removes [config] from the registry. Returns `true` if it was present.
  bool removeConfig(TConfig config) => configs.remove(config);

  //
  //
  //

  /// Looks up a config by [ref]. Returns `null` when no match is found.
  TConfig? findByRef(ConfigRef<dynamic, dynamic>? ref) {
    if (ref == null) return null;
    return configs.firstWhereOrNull((e) => e.ref == ref);
  }
}
