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

import 'package:df_type/df_type.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Extracts nested scopes from a [source] string based on [opening] and
/// [closing] delimiters.
///
/// **Example:**
///
/// ```dart
/// final scopes = extractScopes('{hello{world}', '{', '}');
/// print(scopes); // Prints "([hello, [world]])"
/// ```
Iterable<String> extractScopes(
  String source,
  String opening,
  String closing,
) {
  var index = 0;
  dynamic $parse() {
    final result = <dynamic>[];
    while (index < source.length) {
      if (source.startsWith(opening, index)) {
        index += opening.length;
        result.add($parse());
      } else if (source.startsWith(closing, index)) {
        index += closing.length;
        return result.isNotEmpty ? result : result.first;
      } else {
        final nextOpen = source.indexOf(opening, index);
        final nextClose = source.indexOf(closing, index);
        var nextIndex = nextOpen;
        if (nextOpen == -1 || (nextClose != -1 && nextClose < nextOpen)) {
          nextIndex = nextClose;
        }
        if (nextIndex == -1) {
          result.add(source.substring(index).trim());
          break;
        } else {
          result.add(source.substring(index, nextIndex).trim());
          index = nextIndex;
        }
      }
    }
    return result.isNotEmpty ? result : null;
  }

  return letAsOrNull<List>($parse())?.map((e) => e?.toString()).nonNulls ?? [];
}
