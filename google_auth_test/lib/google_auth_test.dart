/// Common tests for the `tekartik_google_auth` implementations.
///
/// Nothing here is interactive: `signIn()` (which shows a consent ui) is
/// never called, only the state, the caching and the silent restore are
/// tested.
library;

import 'package:tekartik_google_auth/google_auth.dart';
import 'package:test/test.dart';

export 'package:tekartik_google_auth/google_auth.dart';

/// Runs the common tests for [service], using [options].
///
/// [options] must be the implementation specific options (a
/// `TekartikGoogleAuthOptionsIo` for `tekartikGoogleAuthServiceIo`), ideally
/// with a persistence that does not survive the test.
void runGoogleAuthTests({
  required TekartikGoogleAuthService service,
  required TekartikGoogleAuthOptions options,
}) {
  group('google_auth', () {
    test('service', () {
      expect(service.name, isNotEmpty);
      expect(service.toString(), contains(service.name));
    });

    test('auth', () {
      var auth = service.auth(options);
      expect(auth.service, service);
      expect(auth.options, options);
      expect(auth.clientId, options.clientId);
      expect(auth.scopes, options.scopes);
    });

    test('unique', () {
      expect(service.auth(options), same(service.auth(options)));
    });

    test('authViaServiceAccount', () {
      // An empty json: unsupported, or supported and rejected as invalid.
      expect(
        () => service.authViaServiceAccount(
          <String, Object?>{},
          scopes: options.scopes,
        ),
        service.supportsServiceAccount
            ? throwsA(isNot(isA<UnsupportedError>()))
            : throwsUnsupportedError,
      );
    });

    runGoogleAuthAuthTests(auth: service.auth(options));
  });
}

/// Runs the common tests on an existing [auth].
///
/// The [auth] is left as it was found, it is neither signed in nor closed.
void runGoogleAuthAuthTests({required TekartikGoogleAuth auth}) {
  group('auth', () {
    test('authReady', () async {
      expect(await auth.authReady, isTrue);
      // ignore: avoid_print
      print('current user: ${auth.currentUser}');
      expect(auth.isSignedIn, auth.currentUser != null);
    });

    test('currentUser', () async {
      // The first event is the restored user (or null when there is nothing
      // to restore), a later listener gets the current value.
      var user = await auth.onCurrentUser.first;
      // ignore: avoid_print
      print('onCurrentUser: $user');
      expect(user, auth.currentUser);
      expect(await auth.onCurrentUser.first, auth.currentUser);
    });

    test('getClient', () async {
      // Signed out, getClient would start the interactive sign in.
      if (!auth.isSignedIn) {
        // ignore: avoid_print
        print('not signed in, getClient not called');
        return;
      }
      var client = await auth.getClient();
      // ignore: avoid_print
      print('client: $client');
      expect(client, isNotNull);
      var headers = await auth.getAuthHeaders();
      expect(headers!['Authorization'], startsWith('Bearer '));
    });

    group('signInSilently', () {
      test('signInSilently', () async {
        var wasSignedIn = auth.isSignedIn;
        var user = await auth.signInSilently();
        // ignore: avoid_print
        print('signInSilently: $user');
        // A user means signed in, a signed in auth stays signed in.
        expect(auth.isSignedIn, user != null || wasSignedIn);
        if (user != null) {
          expect(auth.currentUser, user);
        }
      });
    }, skip: !auth.service.supportsSignInSilently);
  });
}
