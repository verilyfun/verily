import 'package:test/test.dart';
import 'package:verily_server/src/apps/redirect_uri_policy.dart';
import 'package:verily_server/src/generated/protocol.dart';

Matcher _refused(AppPlatformProblem problem) => throwsA(
  isA<AppPlatformException>().having(
    (error) => error.problem,
    'problem',
    problem,
  ),
);

void main() {
  group('Given a redirect URI to register', () {
    test('when it is an exact https URL or app scheme then it is kept', () {
      for (final value in [
        'https://slopper.example/verily/callback',
        'https://slopper.example/callback?source=verily',
        'com.example.slopper://verily',
        'com.example.slopper:/oauth/callback',
      ]) {
        expect(validateRedirectUri(value), value);
      }
    });

    test('when it is unsafe or not exact then it is refused', () {
      for (final value in [
        'http://slopper.example/callback',
        'https://*.slopper.example/callback',
        'https://slopper.example/callback#token',
        'https://slopper.example/call back',
        ' https://slopper.example/callback',
        'https://user@slopper.example/callback',
        'https:///callback',
        'javascript:alert(1)',
        'data:text/html,hi',
        'file:///etc/passwd',
        'verily://r/abc',
        'intent://scan#Intent;end',
        'myapp:',
        'myapp://',
        'x://a',
        'https://slopper.example/${'a' * 520}',
      ]) {
        expect(
          () => validateRedirectUri(value),
          _refused(AppPlatformProblem.invalidRedirectUri),
          reason: value,
        );
      }
    });

    test('when a list is registered then duplicates collapse', () {
      expect(
        validateRedirectUris([
          'https://slopper.example/a',
          'https://slopper.example/a',
          'com.example.slopper://verily',
        ]),
        ['https://slopper.example/a', 'com.example.slopper://verily'],
      );
    });

    test('when more than ten are registered then the list is refused', () {
      expect(
        () => validateRedirectUris([
          for (var index = 0; index < 11; index += 1)
            'https://slopper.example/$index',
        ]),
        _refused(AppPlatformProblem.tooManyRedirectUris),
      );
    });
  });
}
