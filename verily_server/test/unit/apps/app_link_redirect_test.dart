import 'package:test/test.dart';
import 'package:verily_server/src/apps/linking/app_link_service.dart';

void main() {
  group('Given a registered redirect URI', () {
    test('when it has no query then the parameters start one', () {
      expect(
        appendRedirectQuery('https://slopper.app/verily/callback', {
          'code': 'abc',
          'state': 'xyz',
        }),
        'https://slopper.app/verily/callback?code=abc&state=xyz',
      );
    });

    test('when it has a query then it is kept unchanged as a prefix', () {
      expect(
        appendRedirectQuery('https://slopper.app/cb?from=verily', {
          'code': 'abc',
        }),
        'https://slopper.app/cb?from=verily&code=abc',
      );
      expect(
        appendRedirectQuery('https://slopper.app/cb?', {'code': 'abc'}),
        'https://slopper.app/cb?code=abc',
      );
    });

    test('when it is a custom scheme then it is extended the same way', () {
      expect(
        appendRedirectQuery('com.slopper.app://verily', {
          'error': 'access_denied',
        }),
        'com.slopper.app://verily?error=access_denied',
      );
    });

    test('when a state has reserved characters then it is encoded', () {
      expect(
        appendRedirectQuery('https://slopper.app/cb', {
          'state': 'a b&c=d/é#',
        }),
        'https://slopper.app/cb?state=a+b%26c%3Dd%2F%C3%A9%23',
      );
    });
  });
}
