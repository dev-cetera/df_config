import 'package:df_config/df_config.dart';
import 'package:test/test.dart';

void main() {
  test('A', () {
    final a = getKeyAndDefaultValue(
      'Hello||world',
      const PrimaryPatternSettings(),
    );
    expect(a.key, 'world');
    expect(a.defaultValue, 'Hello');
  });
  test('B', () {
    final a = getKeyAndDefaultValue(
      'Hello;;world',
      const PatternSettings(delimiter: ';;'),
    );
    expect(a.key, 'world');
    expect(a.defaultValue, 'Hello');
  });
  test('C', () {
    final a = getKeyAndDefaultValue(
      'Hello||world',
      const PrimaryPatternSettings(),
      preferKey: 'www',
    );
    expect(a.key, 'www');
    expect(a.defaultValue, 'Hello');
  });
  test('D', () {
    final a = getKeyAndDefaultValue(
      'Hello||WORLD',
      const PrimaryPatternSettings(),
      preferKey: 'www',
    );
    expect(a.key, 'www');
    expect(a.defaultValue, 'Hello');
  });
}
