//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Right-to-left script, bidi control character, and locale-sensitive
// case-folding coverage. df_config operates on UTF-16 code units and
// is direction-agnostic, but the surface area is broad enough that
// we want explicit regression tests rather than just a comment in
// pattern_settings.dart.

import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

void main() {
  setUp(TranslationManager.resetForTesting);

  // ─────────────────────────────────────────────────────────────────────
  // Arabic
  // ─────────────────────────────────────────────────────────────────────
  group('Arabic content (RTL)', () {
    test('Arabic key lookup works case-insensitively (no case in Arabic)',
        () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'ar',
            type: ConfigFileType.YAML,
            read: () async => 'مرحبا: Hello',
          ),
        ),
      );
      expect('default||مرحبا'.tr(), 'Hello');
    });

    test('Arabic value is preserved verbatim through substitution', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'ar',
            type: ConfigFileType.YAML,
            read: () async => 'greeting: مرحبا',
          ),
        ),
      );
      expect('Hello||greeting'.tr(), 'مرحبا');
    });

    test('Arabic args are substituted via secondary pass', () {
      // No active config; pure args path.
      final out = 'Hi {name}'.tr(args: {'name': 'عبد الله'});
      expect(out, 'Hi عبد الله');
    });

    test('full Arabic sentence with placeholder', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'ar',
            type: ConfigFileType.YAML,
            read: () async => 'welcome: "أهلاً وسهلاً {name}"',
          ),
        ),
      );
      expect(
        'Welcome||welcome'.tr(args: {'name': 'فاطمة'}),
        'أهلاً وسهلاً فاطمة',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Hebrew
  // ─────────────────────────────────────────────────────────────────────
  group('Hebrew content (RTL)', () {
    test('Hebrew key lookup', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'he',
            type: ConfigFileType.YAML,
            read: () async => 'שלום: Peace',
          ),
        ),
      );
      expect('default||שלום'.tr(), 'Peace');
    });

    test('Hebrew template with arg', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'he',
            type: ConfigFileType.YAML,
            read: () async => 'hi: "שלום {name}"',
          ),
        ),
      );
      expect('Hi||hi'.tr(args: {'name': 'דוד'}), 'שלום דוד');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Persian / Urdu — extra Arabic-script glyphs
  // ─────────────────────────────────────────────────────────────────────
  group('Persian content (RTL)', () {
    test('Persian-only sentence', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'fa',
            type: ConfigFileType.YAML,
            read: () async => 'hello: سلام دنیا',
          ),
        ),
      );
      expect('Hello world||hello'.tr(), 'سلام دنیا');
    });

    test('Persian digits preserved (۰۱۲۳۴۵۶۷۸۹)', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'fa',
            type: ConfigFileType.YAML,
            read: () async => 'price: قیمت ۱۲۳۴',
          ),
        ),
      );
      expect('Price||price'.tr(), 'قیمت ۱۲۳۴');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Bidi control characters
  // ─────────────────────────────────────────────────────────────────────
  group('Bidi control characters', () {
    // Use escape sequences for invisible bidi control chars so the
    // analyzer doesn't warn about direction-changing literals in
    // source code.
    const lrm = '‎';
    const rlm = '‏';

    test('LRM is preserved in substituted values', () async {
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'mixed',
            type: ConfigFileType.YAML,
            read: () async => 'mix: "Order $lrm#1234"',
          ),
        ),
      );
      final out = 'Order||mix'.tr();
      expect(out.contains(lrm), isTrue);
    });

    test('RLM in a key produces a stable, distinct lookup', () async {
      // A YAML key with an embedded RLM is a different key from the
      // same letters without RLM. We just confirm it doesn't crash and
      // round-trips correctly when both sides use the same RLM marker.
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'mixed',
            type: ConfigFileType.YAML,
            read: () async => '"key${rlm}name": value-rtl',
          ),
        ),
      );
      expect('default||key${rlm}name'.tr(), 'value-rtl');
    });

    test('Bidi-isolation chars (LRI/PDI) pass through verbatim', () {
      const lri = '\u2066'; // LEFT-TO-RIGHT ISOLATE
      const pdi = '\u2069'; // POP DIRECTIONAL ISOLATE
      final out = 'Number: $lri{n}$pdi'.tr(args: {'n': '7'});
      expect(out, 'Number: ${lri}7$pdi');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Locale-sensitive case folding (Turkish dotted-I)
  // ─────────────────────────────────────────────────────────────────────
  group('PatternSettings.caseFold', () {
    test('default toLowerCase: `I` and `İ` both fold to plain `i`', () {
      // Dart's default fold maps both forms to plain `i` — fine for
      // English, but in Turkish `I` should fold to `ı` (dotless).
      // We confirm the merge here so the next test's locale-aware
      // folder has a contrast.
      const s = PatternSettings();
      expect(s.foldKey('I'), 'i');
      expect(s.foldKey('İ'), 'i');
      expect(s.foldKey('IRMAK'), 'irmak');
    });

    test('custom caseFold (Turkish-correct) distinguishes I from İ', () {
      // Tiny Turkish folder: handle the two problem code points.
      String trFold(String input) {
        return input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
      }

      final tr = PatternSettings(caseFold: trFold);
      // Turkish lower-cases `IRMAK` (river) to `ırmak` with dotless ı.
      expect(tr.foldKey('IRMAK'), 'ırmak');
      // Turkish lower-cases `İSTANBUL` to `istanbul` with dotted i.
      expect(tr.foldKey('İSTANBUL'), 'istanbul');
      // Sanity: caseSensitive bypasses folding entirely.
      const cs = PatternSettings(caseSensitive: true);
      expect(cs.foldKey('İSTANBUL'), 'İSTANBUL');
    });

    test('caseFold integrates with Config.map lookups', () {
      String trFold(String input) {
        return input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
      }

      final c = Config<ConfigRef<dynamic, dynamic>>(
        settings: PatternSettings(caseFold: trFold),
      );
      c.setFields({'istanbul': 'İstanbul, Türkiye'});
      // A reference written with the upper-case Turkish dotted-I now
      // resolves correctly.
      expect(c.map<String>('{{İSTANBUL}}'), 'İstanbul, Türkiye');
    });

    test('a throwing caseFold falls back to toLowerCase, never crashes', () {
      final s = PatternSettings(caseFold: (_) => throw StateError('boom'));
      // Must not propagate the throw — defensive fallback.
      expect(s.foldKey('HELLO'), 'hello');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  // Unicode normalisation reminder (NFC vs combining) — documented
  // limitation, but let's pin the expected behaviour.
  // ─────────────────────────────────────────────────────────────────────
  group('Unicode normalisation', () {
    test('precomposed and decomposed forms are NOT auto-equated', () async {
      // 'é' (U+00E9, precomposed) vs 'e' (U+0065) + combining acute
      // (U+0301). These are visually identical but distinct code unit
      // sequences. df_config does not normalise — that is left to the
      // host's caseFold callback. We pin the contract here.
      const precomposed = 'café';
      const decomposed = 'café';
      await TranslationManager.setConfig(
        FileConfig(
          ref: ConfigFileRef(
            ref: 'fr',
            type: ConfigFileType.YAML,
            read: () async => '$precomposed: precomposed-value',
          ),
        ),
      );
      // Same byte sequence → match.
      expect('default||$precomposed'.tr(), 'precomposed-value');
      // Decomposed lookup of the same visual word → falls back to
      // default, because the code units differ.
      expect('default||$decomposed'.tr(), 'default');
    });
  });
}
