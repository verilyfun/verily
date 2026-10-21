import 'package:flutter/foundation.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/core/external_url_launcher.dart';
import 'package:verily_flutter/features/app_link/app_link_repository.dart';

/// Why a link request cannot be answered here.
enum LinkProblem {
  /// Missing parts, an unknown App, or a return address the App never
  /// registered. The server says only "invalid", on purpose.
  invalid,

  /// Too many tries with this App for now.
  rateLimited,

  /// The App was revoked or cannot use Verily right now; the server's
  /// product-safe words come with it.
  appUnavailable,

  /// Anything else, such as no connection. Can be retried.
  generic,
}

/// Where answering a link request stands.
sealed class AppLinkState {
  const AppLinkState();
}

final class AppLinkLoading extends AppLinkState {
  const AppLinkLoading();
}

final class AppLinkUnavailable extends AppLinkState {
  const AppLinkUnavailable(this.problem, {this.appName, this.message});

  final LinkProblem problem;
  final String? appName;
  final String? message;
}

/// Who wants to link and what they get; nothing is shared until the person
/// agrees.
final class AppLinkConsent extends AppLinkState {
  const AppLinkConsent(this.view, {this.answering, this.failed = false});

  final AppLinkRequestView view;

  /// The answer being sent: true to link, false to decline.
  final bool? answering;

  /// The last answer failed and can be sent again.
  final bool failed;
}

/// Handing the person back to the App.
final class AppLinkReturning extends AppLinkState {
  const AppLinkReturning({
    required this.appName,
    required this.redirect,
    required this.linked,
    this.opened,
  });

  final String appName;

  /// The App's registered return address with a one-time code or the
  /// refusal. Opened, never shown.
  final Uri redirect;
  final bool linked;

  /// Whether the App opened; null while it is being opened.
  final bool? opened;
}

/// Answers one App's request to link with this Verily account.
class AppLinkFlow extends ChangeNotifier {
  AppLinkFlow({
    required this.request,
    required this._links,
    required this._openExternal,
  });

  /// The request read from the link, or null when the link was unusable.
  final AppLinkRequest? request;

  final AppLinkRepository _links;
  final ExternalUrlLauncher _openExternal;

  AppLinkState _state = const AppLinkLoading();
  AppLinkState get state => _state;
  bool _disposed = false;

  void _emit(AppLinkState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  Future<void> load() async {
    final request = this.request;
    if (request == null) {
      _emit(const AppLinkUnavailable(LinkProblem.invalid));
      return;
    }
    _emit(const AppLinkLoading());
    try {
      _emit(AppLinkConsent(await _links.describe(request)));
    } on Exception catch (error) {
      _emit(_unavailable(error));
    }
  }

  Future<void> approve() => _answer(link: true);

  Future<void> decline() => _answer(link: false);

  Future<void> _answer({required bool link}) async {
    final consent = _state;
    final request = this.request;
    if (consent is! AppLinkConsent || request == null) return;
    if (consent.answering != null) return;
    _emit(AppLinkConsent(consent.view, answering: link));
    try {
      final redirect = link
          ? await _links.approve(request)
          : await _links.decline(request);
      await _return(
        AppLinkReturning(
          appName: consent.view.appName,
          redirect: Uri.parse(redirect.redirectUrl),
          linked: link,
        ),
      );
    } on Exception catch (error) {
      final unavailable = _unavailable(error, appName: consent.view.appName);
      _emit(
        unavailable.problem == LinkProblem.generic
            ? AppLinkConsent(consent.view, failed: true)
            : unavailable,
      );
    }
  }

  /// Opens the App again, for when it did not open the first time.
  Future<void> openApp() async {
    final returning = _state;
    if (returning is! AppLinkReturning) return;
    await _return(
      AppLinkReturning(
        appName: returning.appName,
        redirect: returning.redirect,
        linked: returning.linked,
      ),
    );
  }

  Future<void> _return(AppLinkReturning returning) async {
    _emit(returning);
    final opened = await _openExternal(returning.redirect);
    _emit(
      AppLinkReturning(
        appName: returning.appName,
        redirect: returning.redirect,
        linked: returning.linked,
        opened: opened,
      ),
    );
  }

  static AppLinkUnavailable _unavailable(Exception error, {String? appName}) {
    final problem = switch (error) {
      AppPlatformException(problem: AppPlatformProblem.rateLimited) =>
        LinkProblem.rateLimited,
      AppPlatformException(
        problem: AppPlatformProblem.linkRequestInvalid ||
            AppPlatformProblem.invalidRedirectUri,
      ) =>
        LinkProblem.invalid,
      AppUnavailableException() => LinkProblem.appUnavailable,
      _ => LinkProblem.generic,
    };
    if (problem == LinkProblem.generic) {
      debugPrint('Answering a link request failed: $error');
    }
    return AppLinkUnavailable(
      problem,
      appName: switch (error) {
        AppUnavailableException(:final appName) => appName,
        _ => appName,
      },
      message: error is AppUnavailableException ? error.message : null,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
