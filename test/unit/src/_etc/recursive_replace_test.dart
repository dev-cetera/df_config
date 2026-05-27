//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Exercises the "killer feature" of df_config: a config can reference
// other keys inside the same config, including nested scopes and list
// items, and the references resolve at load time.

import 'package:df_config/df_config.dart';
import 'package:df_config/src/_etc/_etc.g.dart';
import 'package:test/test.dart';

void main() {
  group('recursiveReplace — pass-through', () {
    test('empty input maps to empty output', () {
      expect(recursiveReplace({}), isEmpty);
    });

    test('no placeholders means no changes', () {
      final src = {
        'a': 1,
        'b': '2',
        'c': [3, 4],
        'd': {'e': '5'},
      };
      expect(recursiveReplace(src), src);
    });

    test('non-string/non-collection leaves are preserved by reference', () {
      final marker = Object();
      final r = recursiveReplace({'k': marker});
      expect(identical(r['k'], marker), isTrue);
    });
  });

  group('recursiveReplace — sibling references', () {
    test('a sibling key resolves at load time', () {
      final r = recursiveReplace({
        'name': 'World',
        'greeting': 'Hello {{name}}',
      });
      expect(r['greeting'], 'Hello World');
    });

    test('chained references resolve transitively', () {
      // c depends on b, b depends on a. flatten/expand pulls a→b→c into
      // place before the leaf-walk substitutes, so all three resolve.
      final r = recursiveReplace({
        'a': 'X',
        'b': '{{a}}',
        'c': '{{b}}',
      });
      expect(r['a'], 'X');
      expect(r['b'], 'X');
      expect(r['c'], 'X');
    });

    test('chained references work across many hops', () {
      final input = <String, dynamic>{'k0': 'base'};
      for (var i = 1; i < 20; i++) {
        input['k$i'] = '{{k${i - 1}}}';
      }
      final r = recursiveReplace(input);
      for (var i = 0; i < 20; i++) {
        expect(r['k$i'], 'base', reason: 'k$i should resolve to "base"');
      }
    });
  });

  group('recursiveReplace — nested scopes', () {
    test('dotted-path reference into a nested map', () {
      final r = recursiveReplace({
        'user': {'name': 'Ada'},
        'greeting': 'Hi {{user.name}}',
      });
      expect(r['greeting'], 'Hi Ada');
    });

    test('multi-level dotted reference', () {
      final r = recursiveReplace({
        'a': {
          'b': {'c': 'deep'},
        },
        'echo': '{{a.b.c}}',
      });
      expect(r['echo'], 'deep');
    });

    test('relative-key shortcut: trailing path segment resolves on its own',
        () {
      // JsonUtility.expandFlattenedJson also adds entries for partial
      // tails, so `{{c}}` can resolve to a deeply-nested leaf when the
      // tail is unambiguous.
      final r = recursiveReplace({
        'a': {
          'b': {'c': 'deep'},
        },
        'echo': '{{c}}',
      });
      expect(r['echo'], 'deep');
    });

    test('inner string can reference an outer key', () {
      // No "scope barrier" — every leaf sees the entire flattened
      // namespace, so an inner leaf can still pull from the root.
      final r = recursiveReplace({
        'salutation': 'Hello',
        'user': {
          'greeting': '{{salutation}}, world',
        },
      });
      final user = r['user'] as Map;
      expect(user['greeting'], 'Hello, world');
    });
  });

  group('recursiveReplace — lists', () {
    test('list items are addressable by index', () {
      final r = recursiveReplace({
        'items': ['x', 'y', 'z'],
        'first': '{{items.0}}',
        'last': '{{items.2}}',
      });
      expect(r['first'], 'x');
      expect(r['last'], 'z');
    });

    test('list items can reference other keys', () {
      final r = recursiveReplace({
        'tag': 'HOT',
        'tags': ['{{tag}}', 'other'],
      });
      final tags = r['tags'] as List;
      expect(tags[0], 'HOT');
      expect(tags[1], 'other');
    });

    test('list inside list inside map', () {
      final r = recursiveReplace({
        'a': 'A',
        'b': [
          ['{{a}}', 'B'],
          ['C', '{{a}}'],
        ],
      });
      final b = r['b'] as List;
      expect((b[0] as List)[0], 'A');
      expect((b[1] as List)[1], 'A');
    });
  });

  group('recursiveReplace — placeholders with defaults', () {
    test('unknown key falls back to default', () {
      final r = recursiveReplace({
        'greeting': 'Hello {{World||missing}}',
      });
      expect(r['greeting'], 'Hello World');
    });

    test('default is overridden by data', () {
      final r = recursiveReplace({
        'missing': 'Earth',
        'greeting': 'Hello {{World||missing}}',
      });
      expect(r['greeting'], 'Hello Earth');
    });
  });

  group('recursiveReplace — guard rails', () {
    test('maxDepth <= 0 throws ArgumentError', () {
      expect(
        () => recursiveReplace({'a': 1}, maxDepth: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => recursiveReplace({'a': 1}, maxDepth: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('self-reference does NOT loop (single-pass at lookup)', () {
      // The flatten/expand only adds the alias once; the leaf-walk
      // resolves each leaf via replacePatterns which is single-pass,
      // so 'a' → '{{a}}' resolves to the value of the sibling 'a' key
      // (which would just be the string itself) without infinite loop.
      expect(
        () => recursiveReplace({'a': '{{a}}'}),
        returnsNormally,
      );
    });

    test('mutually-recursive references resolve to a fixed point', () {
      // a → {{b}}, b → {{a}}. Once flattened, both names share the same
      // entry. The leaf-walk produces some defined output without
      // looping forever — we only assert that it terminates and yields
      // some string.
      final r = recursiveReplace({
        'a': '{{b}}',
        'b': '{{a}}',
      });
      expect(r['a'], isA<String>());
      expect(r['b'], isA<String>());
    });

    test('custom separator threads through', () {
      // Use ':' as the separator instead of '.'. References must use ':'
      // to navigate, and the bug-fix means the literal "separator" never
      // appears in keys regardless.
      final r = recursiveReplace(
        {
          'user': {'name': 'Ada'},
          'echo': '{{user:name}}',
        },
        settings: const PatternSettings(separator: ':'),
      );
      expect(r['echo'], 'Ada');
    });
  });

  group(r'recursiveReplace — regression for $-interpolation bug', () {
    // The previous implementation built nested keys with the literal
    // string `'$settings.separator'` interpolated as
    // `'<settings.toString()>.separator'`. These tests will fail loudly
    // if that ever comes back.

    test('parsed key path uses separator value, not its toString', () {
      final r = recursiveReplace({
        'parent': {'child': 'leaf'},
      });
      // The leaf must resolve via the value of separator ('.'), so a
      // sibling reference like '{{parent.child}}' must work.
      final r2 = recursiveReplace({
        'parent': {'child': 'leaf'},
        'ref': '{{parent.child}}',
      });
      expect(r2['ref'], 'leaf');
      expect(r, isNotEmpty);
    });

    test('list path uses separator value, not its toString', () {
      final r = recursiveReplace({
        'items': ['v0', 'v1'],
        'first': '{{items.0}}',
      });
      expect(r['first'], 'v0');
    });
  });
}
