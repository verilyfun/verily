import 'package:serverpod/serverpod.dart';

/// A plain landing response for the web server root. It names the service
/// and nothing about the deployment.
class RootRoute extends Route {
  RootRoute() : super(methods: {Method.get, Method.head});

  @override
  Future<Result> handleCall(Session session, Request request) async {
    return Response.ok(
      body: Body.fromString(_page, mimeType: MimeType.html),
      headers: Headers.build(
        (headers) => headers.cacheControl = CacheControlHeader(
          maxAge: 300,
          publicCache: true,
        ),
      ),
    );
  }
}

const _page = '''
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Verily</title>
  </head>
  <body>
    <main>
      <h1>Verily</h1>
      <p>Do it, prove it, get paid.</p>
      <p><a href="/app">Open the Verily app</a></p>
    </main>
  </body>
</html>
''';
