import 'package:flutter_test/flutter_test.dart';

import 'package:verily_flutter/core/config/server_config.dart';

void main() {
  test('local development serves public routes from the web port', () {
    final config = serverConfigFrom(apiUrl: 'http://localhost:8180/');

    expect(config.apiUrl.toString(), 'http://localhost:8180/');
    expect(
      config.confirmationsUrl.toString(),
      'http://localhost:8182/api/v1/confirmations',
    );
  });

  test('a deployed API shares its origin unless told otherwise', () {
    expect(
      serverConfigFrom(
        apiUrl: 'https://api.verily.fun',
      ).confirmationsUrl.toString(),
      'https://api.verily.fun/api/v1/confirmations',
    );
    expect(
      serverConfigFrom(
        apiUrl: 'https://api.verily.fun/',
        publicWebUrl: 'https://verily.fun',
      ).confirmationsUrl.toString(),
      'https://verily.fun/api/v1/confirmations',
    );
  });

  test('a malformed server URL stops the build instead of guessing', () {
    for (final url in ['localhost:8180', 'ftp://verily.fun', 'not a url']) {
      expect(
        () => serverConfigFrom(apiUrl: url),
        throwsFormatException,
        reason: url,
      );
    }
  });
}
