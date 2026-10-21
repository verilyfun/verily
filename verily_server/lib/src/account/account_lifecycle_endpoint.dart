import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:verily_server/src/account/account_lifecycle_service.dart';

class AccountLifecycleEndpoint extends Endpoint {
  AccountLifecycleEndpoint({AccountLifecycleService? service})
    : service = service ?? AccountLifecycleService();

  final AccountLifecycleService service;

  @override
  bool get requireLogin => true;

  Future<DateTime> closeAccount(
    Session session, {
    required String confirmation,
  }) {
    return service.closeAccount(
      session,
      authUserId: session.authenticated!.authUserId,
      confirmation: confirmation,
    );
  }
}
