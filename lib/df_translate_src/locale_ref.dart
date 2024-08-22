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

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A reference to a locale, such as Australian English.
class LocaleRef extends ConfigRef<String, Type> {
  //
  //
  //

  /// The language code, such as 'en'.
  final String languageCode;

  /// The country code, such as 'US'.
  final String countryCode;

  //
  //
  //

  /// Creates a new [LocaleRef] from a [languageCode] and a [countryCode].
  LocaleRef(
    this.languageCode,
    this.countryCode,
  ) : super(
          ref: '${languageCode}_$countryCode'.toLowerCase(),
          type: LocaleRef,
        );

  //
  //
  //

  /// Creates a new [LocaleRef] from a [localeCode].
  factory LocaleRef.fromCode(String localeCode) {
    final parts = localeCode.split('_');
    if (parts.length == 2) {
      final languageCode = parts[0];
      final countryCode = parts[1];
      return LocaleRef(languageCode, countryCode);
    }
    return LocaleRef('en', 'us');
  }

  //
  //
  //

  static LocaleRef? tryFromCode(String localeCode) {
    final parts = localeCode.split('_');
    if (parts.length == 2) {
      return LocaleRef(parts[0], parts[1]);
    }
    return null;
  }

  //
  //
  //

  String get localeCode => super.ref!;
}
