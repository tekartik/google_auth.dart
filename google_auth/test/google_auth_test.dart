import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:test/test.dart';

/// Minimal in memory implementation, to test the common base.
class _MockGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  _MockGoogleAuth({required this.service, required this.options});

  static const user = TekartikGoogleAuthUser(
    id: 'mock_id',
    email: 'mock@example.com',
    displayName: 'Mock User',
  );

  /// Stands in for the saved credentials, what [signInSilently] restores.
  TekartikGoogleAuthUser? savedUser;

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    currentUserAdd(user);
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
  Future<void> signOut() async => currentUserAdd(null);

  @override
  Future<AuthClient?> getClient() async => null;
}

class _MockGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'mock';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) => getInstance(
    options,
    () => _MockGoogleAuth(service: this, options: options),
  );
}

TekartikGoogleAuthOptions newOptions({List<String>? scopes}) =>
    TekartikGoogleAuthOptions(clientId: 'mock_client_id', scopes: scopes);

void main() {
  group('TekartikGoogleAuthOptions', () {
    test('scopes are unmodifiable', () {
      var options = newOptions(
        scopes: [tekartikGoogleAuthEmailScope, tekartikGoogleAuthProfileScope],
      );
      expect(options.scopes, ['email', 'profile']);
      expect(() => options.scopes.add('nope'), throwsUnsupportedError);
    });

    test('equality', () {
      expect(newOptions(), newOptions());
      expect(
        newOptions(scopes: [tekartikGoogleAuthEmailScope]),
        newOptions(scopes: [tekartikGoogleAuthEmailScope]),
      );
      expect(
        newOptions(scopes: [tekartikGoogleAuthEmailScope]),
        isNot(newOptions()),
      );
      expect(
        TekartikGoogleAuthOptions(clientId: 'a'),
        isNot(TekartikGoogleAuthOptions(clientId: 'b')),
      );
    });

    test('secret is not printed', () {
      var options = TekartikGoogleAuthOptions(
        clientId: 'id',
        clientSecret: 'super_secret',
      );
      expect(options.toString(), isNot(contains('super_secret')));
    });
  });

  group('TekartikGoogleAuthService', () {
    test('auth() reuses the instance for equal options', () {
      var service = _MockGoogleAuthService();
      var auth = service.auth(newOptions());
      expect(service.auth(newOptions()), same(auth));
      expect(
        service.auth(newOptions(scopes: [tekartikGoogleAuthEmailScope])),
        isNot(same(auth)),
      );
      expect(auth.service, service);
      expect(service.supportsSignInSilently, isTrue);
    });
  });

  group('TekartikGoogleAuth', () {
    late TekartikGoogleAuth auth;

    setUp(() {
      // A new service each time, so the instances are not shared
      auth = _MockGoogleAuthService().auth(
        newOptions(scopes: [tekartikGoogleAuthEmailScope]),
      );
    });

    test('signed out by default', () async {
      expect(auth.clientId, 'mock_client_id');
      expect(auth.scopes, ['email']);
      expect(auth.currentUser, isNull);
      expect(auth.isSignedIn, isFalse);
      expect(await auth.getAuthHeaders(), isNull);
      await auth.close();
    });

    test('sign in/out', () async {
      expect(await auth.signIn(), _MockGoogleAuth.user);
      expect(auth.isSignedIn, isTrue);
      await auth.signOut();
      expect(auth.isSignedIn, isFalse);
      await auth.close();
    });

    test('onCurrentUser replays the current value', () async {
      // The first listen restores, which publishes null when there is nothing
      // to restore. Await it, otherwise signing in below races it.
      var users = <TekartikGoogleAuthUser?>[];
      var subscription = auth.onCurrentUser.listen(users.add);
      await auth.authReady;

      await auth.signIn();
      // Signing in twice only sends one event
      await auth.signIn();
      await auth.signOut();

      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      expect(users, [null, _MockGoogleAuth.user, null]);

      // A late listener immediately gets the current value
      await auth.signIn();
      expect(await auth.onCurrentUser.first, _MockGoogleAuth.user);
      await auth.close();
    });

    test('onCurrentUser.first restores instead of blocking', () async {
      // Nothing saved: resolves to null rather than waiting for a sign in
      expect(await auth.onCurrentUser.first, isNull);
      expect(await auth.authReady, isTrue);
      // Restoring only happens once
      expect(await auth.onCurrentUser.first, isNull);
      await auth.close();
    });

    test('onCurrentUser.first returns the restored user', () async {
      var restorable =
          _MockGoogleAuthService().auth(newOptions()) as _MockGoogleAuth;
      restorable.savedUser = _MockGoogleAuth.user;

      expect(await restorable.onCurrentUser.first, _MockGoogleAuth.user);
      expect(restorable.currentUser, _MockGoogleAuth.user);
      expect(restorable.isSignedIn, isTrue);
      await restorable.close();
    });

    test('authReady restores without listening', () async {
      var restorable =
          _MockGoogleAuthService().auth(newOptions()) as _MockGoogleAuth;
      restorable.savedUser = _MockGoogleAuth.user;

      expect(restorable.currentUser, isNull);
      expect(await restorable.authReady, isTrue);
      expect(restorable.currentUser, _MockGoogleAuth.user);
      await restorable.close();
    });

    test('authReady resolves to false when closed first', () async {
      await auth.close();
      expect(await auth.authReady, isFalse);
    });
  });
}
