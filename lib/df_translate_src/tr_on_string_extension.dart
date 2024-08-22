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
import 'package:df_string/df_string.dart';

import '/src/_index.g.dart';
import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension TrOnStringExtension on String {
  /// Translates the string using the active translation file.
  String tr({
    Map<dynamic, dynamic> args = const {},
    String category = '',
    ReplacePatternsSettings? configSettings = const ReplacePatternsSettings(
      opening: '{',
      closing: '}',
      delimiter: ';;',
      separator: '.',
    ),
  }) {
    final defaultSettings = const ReplacePatternsSettings();
    var input = this;
    if (category.isNotEmpty) {
      input = input
      .splitByLastOccurrenceOf(defaultSettings.delimiter)
      .join('||${category.isNotEmpty ? '$category${defaultSettings.separator}' : ''}');
    }

    final config = TranslationManager.translationFileConfig;
    final temp = config.map<String>(
          this,
          args: args,
          fallback: this,
          settings: defaultSettings,
        ) ??
        this;
    return temp.replacePatterns(
      args.mapKeys((k) => k.toString()),
      settings: configSettings ?? config.settings,
    );
  }
}