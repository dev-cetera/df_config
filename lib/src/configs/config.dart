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

/// A configuration class that maps placeholder strings to values.
///
/// Holds two parallel representations of the same data:
///  - [data] is the raw, untouched map as ingested via [setFields].
///  - [parsedFields] is the same map after recursive placeholder
///    resolution and flatten/expand into dotted keys, suitable for direct
///    lookup by [map].
class Config<TConfigRef extends ConfigRef<dynamic, dynamic>> extends Equatable {
  //
  //
  //

  /// The reference to the config file (or `null` for an in-memory config).
  final TConfigRef? ref;

  /// The parsed, flattened-and-expanded fields used for lookups.
  late final Map<dynamic, dynamic> parsedFields;

  /// The unparsed data as it was ingested.
  late final Map<dynamic, dynamic> data;

  /// Optional hook to override how a key/default pair resolves before the
  /// normal map lookup is attempted.
  final dynamic Function(TGetKeyAndDefaultValueResult textResult)? mapper;

  /// Placeholder syntax used by this config.
  final PatternSettings settings;

  //
  //
  //

  Config({
    this.ref,
    this.settings = const PatternSettings(),
    this.mapper,
  }) {
    parsedFields = <dynamic, dynamic>{};
    data = <dynamic, dynamic>{};
  }

  //
  //
  //

  /// Replaces the fields of this config with those derived from [source].
  ///
  /// The previous [data] and [parsedFields] are cleared first, so calling
  /// this twice does not accumulate stale state.
  void setFields(Map<dynamic, dynamic> source) {
    data
      ..clear()
      ..addAll(source);
    parsedFields
      ..clear()
      ..addAll(
        JsonUtility.i.expandJson(
          recursiveReplace(source, settings: settings)
              .mapKeys((e) => e.toString()),
        ),
      );
  }

  //
  //
  //

  /// Maps [value] against this config's fields, returning the resolved
  /// value cast to [T] (or [fallback] / `null` if the resolution does
  /// not produce a value of that type).
  ///
  /// [args] supplies ad-hoc placeholder values that take precedence over
  /// [parsedFields]. [preferKey] forces a specific key, overriding any key
  /// implied by `default||key` syntax. [settings] overrides this config's
  /// default [PatternSettings] for this call only.
  T? map<T>(
    String value, {
    Map<dynamic, dynamic> args = const {},
    T? fallback,
    String? preferKey,
    PatternSettings? settings,
  }) {
    final effectiveSettings = settings ?? this.settings;
    final expandedArgs = JsonUtility.i.expandJson(
      args.mapKeys((e) => e.toString()),
    );
    final combined = <dynamic, dynamic>{...parsedFields, ...expandedArgs};
    final wrapped = _wrapIfNeeded(
      value,
      opening: effectiveSettings.opening,
      closing: effectiveSettings.closing,
    );
    final replaced = replacePatterns(
      wrapped,
      combined,
      preferKey: preferKey,
      settings: effectiveSettings,
    );
    return letOrNull<T>(replaced) ?? fallback;
  }

  //
  //
  //

  /// Identity comes from the [ref]; two configs with equal refs are
  /// considered equal even if their data diverges in flight.
  @override
  List<Object?> get props => [ref];
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Wraps [input] with [opening]/[closing] when it does not already contain
/// either token. Inputs that already contain a placeholder delimiter (in
/// either direction) are left alone so existing patterns are not nested
/// inadvertently.
String _wrapIfNeeded(
  String input, {
  required String opening,
  required String closing,
}) {
  if (opening.isEmpty || closing.isEmpty) return input;
  var output = input;
  if (!input.contains(opening)) {
    output = '$opening$output';
  }
  if (!input.contains(closing)) {
    output = '$output$closing';
  }
  return output;
}
