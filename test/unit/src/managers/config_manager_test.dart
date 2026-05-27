//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

Config<ConfigRef<dynamic, dynamic>> _cfg(String ref) {
  return Config<ConfigRef<dynamic, dynamic>>(
    ref: ConfigRef<dynamic, dynamic>(ref: ref),
  );
}

void main() {
  group('ConfigManager — construction', () {
    test('empty by default', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      expect(m.configs, isEmpty);
    });

    test('initial configs are imported', () {
      final initial = <Config<ConfigRef<dynamic, dynamic>>>{
        _cfg('A'),
        _cfg('B'),
      };
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>(initial);
      expect(m.configs, hasLength(2));
    });
  });

  group('ConfigManager.setConfig', () {
    test('adds a new config', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      final added = m.setConfig(_cfg('X'));
      expect(m.configs, contains(added));
    });

    test('replaces existing config with the same ref', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      final a = _cfg('X')..setFields({'v': 'old'});
      final b = _cfg('X')..setFields({'v': 'new'});
      m.setConfig(a);
      m.setConfig(b);
      expect(m.configs, hasLength(1));
      expect(identical(m.configs.first, b), isTrue);
    });

    test('returns identical when re-adding the same instance', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      final a = _cfg('X');
      final r1 = m.setConfig(a);
      final r2 = m.setConfig(a);
      expect(identical(r1, r2), isTrue);
      expect(m.configs, hasLength(1));
    });

    test('keeps configs with different refs', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      m.setConfig(_cfg('A'));
      m.setConfig(_cfg('B'));
      expect(m.configs, hasLength(2));
    });

    test('refless configs collapse to one slot', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      m.setConfig(Config<ConfigRef<dynamic, dynamic>>());
      m.setConfig(Config<ConfigRef<dynamic, dynamic>>());
      expect(m.configs, hasLength(1));
    });
  });

  group('ConfigManager.removeConfig', () {
    test('returns true and clears when present', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      final a = _cfg('X');
      m.setConfig(a);
      expect(m.removeConfig(a), isTrue);
      expect(m.configs, isEmpty);
    });

    test('returns false when not present', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      expect(m.removeConfig(_cfg('X')), isFalse);
    });
  });

  group('ConfigManager.findByRef', () {
    test('returns null for null ref', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      expect(m.findByRef(null), isNull);
    });

    test('returns null when no config matches', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      expect(
        m.findByRef(const ConfigRef<dynamic, dynamic>(ref: 'X')),
        isNull,
      );
    });

    test('returns the stored config when one matches', () {
      final m = ConfigManager<Config<ConfigRef<dynamic, dynamic>>>({});
      final a = _cfg('X');
      m.setConfig(a);
      expect(
        m.findByRef(const ConfigRef<dynamic, dynamic>(ref: 'X')),
        same(a),
      );
    });
  });
}
