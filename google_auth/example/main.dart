// ignore_for_file: avoid_print

/// tekartik_google_auth alone: an in memory implementation built on the
/// mixins (what a unit test fake looks like), used through the common api.
///
/// A real program uses `tekartikGoogleAuthServiceIo`
/// (tekartik_google_auth_io) or `tekartikGoogleAuthServiceFlutter`
/// (tekartik_google_auth_flutter) instead, see the README.
library;

import 'package:tekartik_google_auth/google_auth_impl.dart';

class MemoryGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;
  @override
  final TekartikGoogleAuthOptions options;

  MemoryGoogleAuth({required this.service, required this.options});

  /// What a real implementation keeps in its saved credentials.
  TekartikGoogleAuthUser? savedUser;

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    // A real implementation shows the consent screen here.
    savedUser = const TekartikGoogleAuthUser(
      id: '1234',
      email: 'me@example.com',
    );
    currentUserAdd(savedUser);
    return currentUser;
  }

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async {
    if (savedUser != null) {
      currentUserAdd(savedUser);
    }
    return currentUser;
  }

  @override
  Future<void> signOut() async {
    savedUser = null;
    currentUserAdd(null);
  }

  @override
  Future<AuthClient?> getClient() async => null;
}

class MemoryGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'memory';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) => getInstance(
    options,
    () => MemoryGoogleAuth(service: this, options: options),
  );
}

/// Shared code: only the common api.
Future<void> run(TekartikGoogleAuthService service) async {
  var auth = service.auth(
    TekartikGoogleAuthOptions(
      clientId: 'my_client_id',
      scopes: [tekartikGoogleAuthEmailScope],
    ),
  );
  var subscription = auth.onCurrentUser.listen(
    (user) => print('current user: ${user?.email}'),
  );
  // Nothing saved yet: restored to null, so sign in.
  var user = await auth.onCurrentUser.first ?? await auth.signIn();
  print('signed in: ${user?.email}');
  await auth.signOut();
  await subscription.cancel();
  await auth.close();
}

Future<void> main() async {
  await run(MemoryGoogleAuthService());
}
