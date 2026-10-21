import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';
import 'package:uuid/validation.dart';
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/features/actions/action_repository.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';

/// The device's IANA time zone, such as `Africa/Lagos`.
///
/// A daily action's periods are computed in its zone on the server, so a new
/// action starts in the creator's own zone rather than UTC. The field stays
/// editable; when the zone can't be read the editor starts at UTC and the
/// creator sees it.
final FutureProvider<String> deviceTimeZoneProvider = FutureProvider<String>((
  ref,
) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } on Object catch (error) {
    debugPrint('The device time zone could not be read: $error');
    return 'UTC';
  }
});

/// The server's starting points for a new action.
final FutureProvider<List<ActionTemplate>> editorTemplatesProvider =
    FutureProvider.autoDispose<List<ActionTemplate>>(
      (ref) => ref.watch(actionRepositoryProvider).listTemplates(),
    );

/// One of the creator's saved actions, as the editor opens it. A malformed
/// link fails like a missing action, with [ResourceNotFoundException],
/// without asking the server.
final FutureProviderFamily<ActionOpportunity, String> editorActionProvider =
    FutureProvider.autoDispose.family<ActionOpportunity, String>((
      ref,
      actionId,
    ) {
      if (!UuidValidation.isValidUUIDFormat(fromString: actionId)) {
        throw ResourceNotFoundException(
          resource: MissingResource.action,
          message: 'Malformed action link.',
        );
      }
      return ref
          .watch(actionRepositoryProvider)
          .preview(UuidValue.fromString(actionId));
    });

/// The creator's Apps that can confirm proof now. A revoked App can no longer
/// confirm anything, so it is never offered.
final FutureProvider<List<VerilyAppView>> editorActiveAppsProvider =
    FutureProvider.autoDispose<List<VerilyAppView>>((ref) async {
      final apps = await ref.watch(appsRepositoryProvider).listApps();
      return [
        for (final app in apps)
          if (app.status == VerilyAppStatus.active) app,
      ];
    });
