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

extension TrOnStringX on String {
  /// Translates the string using the active translation file.
  String tr({
    Map<dynamic, dynamic> args = const {},
    String? preferKey,
    String category = '',
    PatternSettings? secondarySettings = const SecondaryPatternSettings(),
  }) {
    final config = TranslationManager.config;
    final settings = config.settings;
    // Apply the category to the input if provided.
    var input = this;
    if (category.isNotEmpty) {
      final delimiter = settings.delimiter;
      final separator = settings.separator;
      input = input
          .splitByLastOccurrenceOf(delimiter)
          .join(
            '$delimiter${category.isNotEmpty ? '$category$separator' : ''}',
          );
    }
    // Process the input with the mapper function if provided.
    final p = getKeyAndDefaultValue(input, settings, preferKey: preferKey);
    var output1 = config.mapper?.call(p)?.toString();
    // Process the input with the primary settings.
    output1 ??=
        config.map<String>(
          input,
          args: args,
          fallback: input,
          preferKey: preferKey,
        ) ??
        input;
    // Process the output again with the secondary settings if provided.
    if (secondarySettings != null) {
      final output2 =
          config.map<String>(
            output1,
            args: args,
            fallback: output1,
            preferKey: preferKey,
            settings: secondarySettings,
          ) ??
          output1;
      return output2;
    }
    return output1;
  }
}
