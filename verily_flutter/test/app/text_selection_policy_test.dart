import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-input text selection requires the shared error component', () {
    final libraryFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in libraryFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('SelectionArea(')),
        reason: '${file.path} must not make an entire surface selectable.',
      );
      expect(
        source,
        isNot(contains('SelectableRegion(')),
        reason: '${file.path} must not make an entire region selectable.',
      );

      if (file.path.endsWith('verily_copyable_error_text.dart')) continue;
      expect(
        source,
        isNot(contains('SelectableText(')),
        reason:
            '${file.path} must use VerilyCopyableErrorText for deliberate '
            'non-input selection.',
      );
    }
  });

  test('copy names Verily and never the app it was extracted from', () {
    final messages = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, Object?>;
    for (final MapEntry(:key, :value) in messages.entries) {
      if (key.startsWith('@') || value is! String) continue;
      expect(
        value.toLowerCase(),
        isNot(anyOf(contains('kickjump'), contains('nifty'))),
        reason: key,
      );
    }
  });
}
