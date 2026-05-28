//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Safety-critical regression tests. Each test pins a guard that was
// added as a result of the life-critical audit. If any of these fail,
// the package has regressed on a guarantee that medical / military
// hosts rely on.

import 'package:df_config/df_config.dart';
import 'package:df_config/src/_etc/_etc.g.dart';
import 'package:test/test.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────
  // A1: tr() error sink — silent failures must be observable when the
  // host opts in.
  // ─────────────────────────────────────────────────────────────────────
  group('A1: TranslationManager.onError surfaces internal errors', () {
    setUp(TranslationManager.resetForTesting);

    test('tr() forwards its caught error to onError when one is set', () async {
      Object? captured;
      // A throwing mapper is the easiest reproducible failure path.
      final cfg = FileConfig(
        ref: const ConfigFileRef(ref: 'en'),
        mapper: (_) => throw StateError('boom'),
      );
      await TranslationManager.setConfig(cfg);
      TranslationManager.onError = (source, error, stack) {
        captured = error;
      };
      // Even though tr() never throws, the error is forwarded.
      'hello'.tr();
      expect(captured, isA<StateError>());
    });

    test('default onError is null — backward compatible silent mode', () {
      // No sink installed → no observable side effect, tr() still
      // returns a string and never throws.
      expect(() => '{{x}}'.tr(), returnsNormally);
    });

    test('a buggy onError sink does NOT break the host', () {
      TranslationManager.onError = (_, __, ___) => throw StateError('nope');
      // The buggy sink is wrapped; tr() still returns a string.
      expect(() => 'x'.tr(), returnsNormally);
    });

    test('resetForTesting clears the sink as well', () {
      TranslationManager.onError = (_, __, ___) {};
      TranslationManager.resetForTesting();
      expect(TranslationManager.onError, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // A2: Cyclic YAML must be detected at conversion time, never cause an
  // unbounded loop in downstream code.
  // ─────────────────────────────────────────────────────────────────────
  group('A2: cyclic YAML', () {
    test('YAML with an anchor loop throws ConfigParseException', () {
      // YAML 1.2 allows anchors and aliases that form a cycle. The
      // `yaml` package preserves the cycle in the decoded structure.
      const cyclic = '''
&loop
a: *loop
''';
      expect(
        () => yamlToData(cyclic),
        throwsA(isA<ConfigParseException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // A3: programmatic cyclic Map must not crash recursiveReplace.
  // ─────────────────────────────────────────────────────────────────────
  group('A3: cyclic input to recursiveReplace', () {
    test('self-referencing map throws StateError up-front', () {
      final m = <String, dynamic>{'a': 1};
      m['self'] = m;
      expect(
        () => recursiveReplace(m),
        throwsA(isA<StateError>()),
      );
    });

    test('mutually-cyclic maps throw StateError', () {
      final a = <String, dynamic>{};
      final b = <String, dynamic>{};
      a['b'] = b;
      b['a'] = a;
      expect(
        () => recursiveReplace({'root': a}),
        throwsA(isA<StateError>()),
      );
    });

    test('list that contains itself throws StateError', () {
      final list = <dynamic>[1, 2];
      list.add(list);
      expect(
        () => recursiveReplace({'k': list}),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // A4: a buggy settings.callback must not derail unrelated patterns.
  // ─────────────────────────────────────────────────────────────────────
  group('A4: throwing settings.callback is sandboxed', () {
    test('replacement falls through to suggested → default chain', () {
      final settings = PatternSettings(
        callback: (k, v, d) => throw StateError('callback broken'),
      );
      expect(
        replacePatterns(
          '{{Hello||name}}',
          {'name': 'World'},
          settings: settings,
        ),
        'World',
        reason: 'falls through to suggested value when callback throws',
      );
    });

    test('multiple matches all process even when one callback throws', () {
      var firstCall = true;
      final settings = PatternSettings(
        callback: (k, v, d) {
          if (firstCall) {
            firstCall = false;
            throw StateError('boom');
          }
          return v?.toString() ?? d;
        },
      );
      expect(
        replacePatterns(
          '{{a}} {{b}}',
          {'a': 'X', 'b': 'Y'},
          settings: settings,
        ),
        'X Y',
      );
    });

    test('callback failure is reported via TranslationManager.onError', () {
      Object? captured;
      TranslationManager.onError = (source, error, stack) {
        captured = error;
      };
      addTearDown(() => TranslationManager.onError = null);

      final settings = PatternSettings(
        callback: (k, v, d) => throw StateError('boom'),
      );
      replacePatterns('{{x}}', const {}, settings: settings);
      expect(captured, isA<StateError>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // A5/B2: collisions in stringification of distinct keys must NOT
  // silently overwrite.
  // ─────────────────────────────────────────────────────────────────────
  group('A5/B2: key collision detection', () {
    test('Config.setFields refuses two keys that collide on toString()', () {
      final c = Config<ConfigRef<dynamic, dynamic>>();
      expect(
        () => c.setFields({1: 'a', '1': 'b'}),
        throwsA(isA<StateError>()),
      );
    });

    test('yamlToData throws on colliding YAML keys', () {
      // YAML allows integer and string keys side-by-side. After
      // stringification they collide.
      const src = '''
1: a
'1': b
''';
      expect(
        () => yamlToData(src),
        throwsA(isA<ConfigParseException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // B5: CSV strict mode rejects malformed rows.
  // ─────────────────────────────────────────────────────────────────────
  group('B5: CSV strict mode', () {
    test('default: silently skips rows with <2 columns', () {
      // Backwards-compat path — short rows are dropped without comment.
      expect(csvToData('a,1\nshort\nb,2\n'), {'a': '1', 'b': '2'});
    });

    test('strict: short row throws ConfigParseException', () {
      expect(
        () => csvToData('a,1\nshort\nb,2\n', const PatternSettings(), true),
        throwsA(
          isA<ConfigParseException>().having((e) => e.source, 'source', 'csv'),
        ),
      );
    });

    test('duplicate keys throw regardless of strict mode', () {
      expect(
        () => csvToData('a,1\na,2\n'),
        throwsA(isA<ConfigParseException>()),
      );
      expect(
        () => csvToData('a,1\na,2\n', const PatternSettings(), true),
        throwsA(isA<ConfigParseException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // C2: replacePatterns configurable limits.
  // ─────────────────────────────────────────────────────────────────────
  group('C2: configurable replacePatterns limits', () {
    test('lower maxInputLength rejects input above the new cap', () {
      expect(
        () => replacePatterns('a' * 200, const {}, maxInputLength: 100),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('higher maxInputLength accepts larger inputs', () {
      final big = 'a' * (kReplacePatternsMaxInputLength + 100);
      expect(
        () => replacePatterns(
          big,
          const {},
          maxInputLength: kReplacePatternsMaxInputLength + 1000,
        ),
        returnsNormally,
      );
    });

    test('maxMatches=0 or negative is rejected', () {
      expect(
        () => replacePatterns('x', const {}, maxMatches: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => replacePatterns('x', const {}, maxMatches: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('maxInputLength=0 or negative is rejected', () {
      expect(
        () => replacePatterns('x', const {}, maxInputLength: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('hitting maxMatches throws a clear StateError', () {
      // Generate input with more matches than the limit.
      final src = List.generate(20, (_) => '{{x}}').join();
      expect(
        () => replacePatterns(src, {'x': 'V'}, maxMatches: 5),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // setFields atomicity — never observe a half-written config.
  // ─────────────────────────────────────────────────────────────────────
  group('Config.setFields atomicity', () {
    test('a throwing recursiveReplace leaves previous state intact', () {
      // First, install a known-good state.
      final c = Config<ConfigRef<dynamic, dynamic>>();
      c.setFields({'a': '1'});
      expect(c.data['a'], '1');
      expect(c.parsedFields['a'], '1');

      // Now build a cyclic input — recursiveReplace will throw via
      // _assertNoCycles BEFORE either map is mutated.
      final m = <String, dynamic>{'b': 1};
      m['self'] = m;
      expect(() => c.setFields(m), throwsA(isA<StateError>()));

      // Previous state must survive.
      expect(c.data, {'a': '1'});
      expect(c.parsedFields['a'], '1');
    });

    test('a colliding-key input leaves previous state intact', () {
      final c = Config<ConfigRef<dynamic, dynamic>>();
      c.setFields({'a': '1'});
      expect(
        () => c.setFields({1: 'x', '1': 'y'}),
        throwsA(isA<StateError>()),
      );
      expect(c.data, {'a': '1'});
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Cycle-checker depth limit — even acyclic but pathologically deep
  // input must fail fast instead of blowing the Dart stack.
  // ─────────────────────────────────────────────────────────────────────
  group('Cycle-checker depth bound', () {
    test('extremely deep acyclic map triggers the depth guard', () {
      // Build a deeply-nested chain. We go past the cycle-checker's
      // own limit but stay finite, so this is the depth path
      // (not the cycle path).
      var deep = <String, dynamic>{'leaf': 'value'};
      for (var i = 0; i < 1500; i++) {
        deep = <String, dynamic>{'k': deep};
      }
      expect(
        () => recursiveReplace(deep),
        throwsA(isA<StateError>()),
      );
    });

    test('moderate depth (under the limit) passes', () {
      var deep = <String, dynamic>{'leaf': 'value'};
      for (var i = 0; i < 50; i++) {
        deep = <String, dynamic>{'k': deep};
      }
      expect(() => recursiveReplace(deep), returnsNormally);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Final sanity: the auditing didn't break the example.
  // ─────────────────────────────────────────────────────────────────────
  group('Sanity: the README example still works', () {
    setUp(TranslationManager.resetForTesting);

    test('Hey {{Example {App|app}||app.title}} dude resolves correctly', () {
      expect(
        'Hey {{Example {App|app}||app.title}} dude'.tr(
          args: {'app': 'Application'},
        ),
        'Hey Example Application dude',
      );
    });
  });
}
