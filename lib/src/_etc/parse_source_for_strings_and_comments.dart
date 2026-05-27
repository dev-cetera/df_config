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

/// Extracts all quoted strings and comments from [source].
///
/// Strategy: walk the source once, classifying each region into exactly one
/// of {multi-line comment, single-line comment, quoted string, code}. Each
/// region is classified by its *opening* token so nested or interleaved
/// tokens cannot be double-counted. This avoids regex-order pitfalls (e.g.
/// a `//` inside a `"..."` string being misread as a comment, or `*/`
/// inside a string ending a comment).
@internal
ParseSourceForStringsAndCommentsResult parseSourceForStringsAndComments(
  String source,
) {
  final multiLineComments = <String>[];
  final singleLineComments = <String>[];
  final quotedStrings = <String>[];

  final n = source.length;
  var i = 0;
  while (i < n) {
    final remaining = n - i;
    // Multi-line comment: /* ... */
    if (remaining >= 2 && source[i] == '/' && source[i + 1] == '*') {
      final end = source.indexOf('*/', i + 2);
      final stop = end == -1 ? n : end + 2;
      multiLineComments.add(source.substring(i, stop));
      i = stop;
      continue;
    }
    // Single-line comment: // ... (terminated by \n or EOF)
    if (remaining >= 2 && source[i] == '/' && source[i + 1] == '/') {
      var stop = source.indexOf('\n', i + 2);
      if (stop == -1) stop = n;
      singleLineComments.add(source.substring(i, stop));
      i = stop;
      continue;
    }
    // Quoted string: " ... " or ' ... '
    final ch = source[i];
    if (ch == '"' || ch == "'") {
      final quote = ch;
      var j = i + 1;
      while (j < n) {
        final c = source[j];
        if (c == r'\' && j + 1 < n) {
          j += 2;
          continue;
        }
        if (c == quote) {
          j++;
          break;
        }
        j++;
      }
      quotedStrings.add(source.substring(i, j));
      i = j;
      continue;
    }
    i++;
  }

  return ParseSourceForStringsAndCommentsResult(
    List.unmodifiable(quotedStrings),
    List.unmodifiable(multiLineComments),
    List.unmodifiable(singleLineComments),
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The result of [parseSourceForStringsAndComments].
@internal
class ParseSourceForStringsAndCommentsResult {
  //
  //
  //

  final List<String> quotedStrings;
  final List<String> multiLineComments;
  final List<String> singleLineComments;

  //
  //
  //

  const ParseSourceForStringsAndCommentsResult(
    this.quotedStrings,
    this.multiLineComments,
    this.singleLineComments,
  );
}
