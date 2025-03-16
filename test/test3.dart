import 'package:df_config/df_config.dart';

void main() {
  final settings = const PrimaryPatternSettings();

  final config = FileConfig(mapper: (key) => 'HOOOLA!');

  config.setFields({
    'ok': {'dude': 'Hello'},
  });

  final a = config.map<String>('ok {{hey;;ok.dude}} ok', settings: settings);
  // final a = replacePatterns(
  //   'ok <<<hey;;ok.dude>>> ok',
  //   config.parsedFields,
  //   settings: settings,
  // );
  print(a);

  // test('A', () {
  //   final a = getKeyAndDefaultValue(
  //     '',
  //     'Hello||world',
  //     const ReplacePatternsSettings(),
  //   );
  //   expect(a.key, 'world');
  //   expect(a.defaultValue, 'Hello');
  // });
}
