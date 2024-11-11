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

import 'package:df_collection/df_collection.dart';
import 'package:df_type/df_type.dart';
import 'package:equatable/equatable.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A configuration class, used to map strings to values.
class Config<TConfigRef extends ConfigRef<dynamic, dynamic>> extends Equatable {
  //
  //
  //

  /// The reference to the config file.
  final TConfigRef? ref;

  /// The parsed fields of the config.
  late final Map<dynamic, dynamic> parsedFields;

  // The unparsed data of the config.
  late final Map<dynamic, dynamic> data;

  //
  //
  //

  final ReplacePatternsSettings settings;

  //
  //
  //

  Config({
    this.ref,
    this.settings = const ReplacePatternsSettings(),
  }) {
    this.parsedFields = {};
    this.data = {};
  }

  //
  //
  //

  /// Sets the fields of the config from a JSON map.
  void setFields(Map<dynamic, dynamic> data) {
    this.data
      ..clear()
      ..addAll(data);
    this.parsedFields
      ..clear()
      ..addAll(
        JsonUtility.i.expandJson(
          recursiveReplace(
            data,
            settings: this.settings,
          ).mapKeys(
            (e) => e.toString(),
          ),
        ),
      );
  }

  //
  //
  //

  /// Maps a string to a value using this config.
  T? map<T>(
    String value, {
    Map<dynamic, dynamic> args = const {},
    T? fallback,
    ReplacePatternsSettings? settings,
  }) {
    final settingsOverride = settings ?? this.settings;
    final expandedArgs = JsonUtility.i.expandJson(args.mapKeys((e) => e.toString()));
    var data = {
      ...this.parsedFields,
      ...expandedArgs,
    };
    var input = _addOpeningAndClosing(
      value,
      opening: settingsOverride.opening,
      closing: settingsOverride.closing,
    );
    final r = replacePatterns(
      input,
      data,
      settings: settingsOverride,
    );
    final res = letOrNull<T>(r) ?? fallback;
    return res;
  }

  //
  //
  //

  @override
  List<Object?> get props => [...?this.ref?.props];
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String _addOpeningAndClosing(
  String input, {
  required String opening,
  required String closing,
}) {
  var output = input;
  if (!input.contains(opening)) {
    output = '$opening$output';
  }
  if (!input.contains(closing)) {
    output = '$output$closing';
  }
  return output;
}
