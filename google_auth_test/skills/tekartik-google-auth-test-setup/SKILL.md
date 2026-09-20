---
name: tekartik-google-auth-test-setup
description: >-
  Use when running the shared tekartik_google_auth test suite against an
  implementation (tekartik_google_auth_io, tekartik_google_auth_flutter or a
  custom one) or when driving a TekartikGoogleAuth by hand from a dev menu:
  runGoogleAuthTests(service:, options:), runGoogleAuthAuthTests(auth:),
  tekartikGoogleAuthMainMenu(context:),
  TekartikGoogleAuthMainMenuContext(auth:), mainMenu, keyValuesMenu, and the
  package:tekartik_google_auth_test/google_auth_test.dart /
  package:tekartik_google_auth_test/menu/google_auth_client_menu.dart imports.
---

# tekartik_google_auth_test: shared tests and dev menu

`tekartik_google_auth_test` is the test helper of the google auth stack (the
equivalent of `tekartik_firebase_auth_test`): a non-interactive suite every
implementation of `TekartikGoogleAuth` must pass, and a `tekartik_app_dev_menu`
menu to drive a real sign in by hand.

## Guidelines

* Dependency (git, not on pub.dev), always a **dev** dependency - except for
  an app whose dev menu ships in a debug build:
  ```yaml
  dev_dependencies:
    tekartik_google_auth_test:
      git:
        url: https://github.com/tekartik/google_auth.dart
        path: google_auth_test
      version: '>=0.1.0'
  ```
* Two imports:
  * `package:tekartik_google_auth_test/google_auth_test.dart` for the suite;
    it re-exports `package:tekartik_google_auth/google_auth.dart`, so a test
    file needs only this one plus the implementation and `package:test`.
  * `package:tekartik_google_auth_test/menu/google_auth_client_menu.dart` for
    the menu; it re-exports `tekartik_app_dev_menu`'s `dev_menu.dart`
    (`mainMenu`, `menu`, `item`, `write`, `keyValuesMenu`, `kvFromVar`) and
    the common auth api.
* `runGoogleAuthTests(service: <the global service>, options: <implementation
  options>)` declares the whole suite, call it from `main()` (optionally
  inside a `group`). `options` must be the implementation specific options
  (a `TekartikGoogleAuthOptionsIo` for `tekartikGoogleAuthServiceIo`), and
  must not touch anything persistent: pass
  `credentialsPersistence: TekartikFirebasePersistenceMemory()` on io.
  A mock `clientId`/`clientSecret` is enough, the suite never contacts google.
* What it checks: `service.name`/`toString()`, that `auth(options)` carries
  the service, options, `clientId` and `scopes`, that equal options return the
  *same* instance, that `authViaServiceAccount` throws `UnsupportedError` when
  `supportsServiceAccount` is false, then everything of
  `runGoogleAuthAuthTests`.
* `runGoogleAuthAuthTests(auth: <an existing auth>)` runs the same auth level
  checks (`authReady`, `onCurrentUser` replay, `getClient`/`getAuthHeaders`
  consistency, `signInSilently` - skipped when
  `service.supportsSignInSilently` is false) on an auth that may already be
  signed in. It leaves the auth as it found it: it neither signs it in nor
  closes it. Use it on a real signed in auth for an end to end check.
* **Nothing is interactive**: `signIn()` is never called, so no consent ui
  pops up and the suite is safe in ci. Test the real sign in by hand with the
  menu instead.
* Writing a new implementation: make it pass `runGoogleAuthTests` first, that
  is what the io and flutter implementations do. See the
  `tekartik-google-auth-io-setup` and `tekartik-google-auth-flutter-setup`
  skills for the concrete options, and `tekartik_google_auth`'s
  implementation skill for the mixins.
* Dev menu: `tekartikGoogleAuthMainMenu(context:
  TekartikGoogleAuthMainMenuContext(auth: auth))` inside a `mainMenu(args,
  () { ... })` body. It offers `signIn` (`service`, `current user`,
  `register`/`cancel on current user`, `authReady`, `signIn`,
  `signInSilently`, `signOut`) and `client` (`getClient`, printing the token
  expiry, scopes and whether there is a refresh token, and `getAuthHeaders`).
  It works on any `TekartikGoogleAuth`, console or flutter.
* Keep the real client id/secret out of the source: declare them with
  `'my_key'.kvFromVar()` and a `keyValuesMenu('kv', [...])` entry, so they are
  typed once and saved as vars, as
  `example/google_auth_io_menu_example.dart` does. Run it with
  `dart run example/google_auth_io_menu_example.dart`.
* Flutter: the same menu runs in a flutter app (`mainMenu` is the universal
  `tekartik_test_menu` entry point) built on
  `tekartikGoogleAuthServiceFlutter.auth(...)`; only the widget/plugin side
  needs a device, so keep it in a debug-only screen or an example app.
* Anti-patterns: a test depending on the real file `.local/
  access_credentials.yaml` (use the memory persistence); calling `signIn()` in
  a test; closing the auth between `runGoogleAuthTests` groups (the service
  caches the instance, a closed one stays cached with a closed
  `onCurrentUser`); shipping the menu, a real client id or a client secret in
  a release build.

## Examples

### Shared suite on the io implementation

```dart
@TestOn('vm')
library;

import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:tekartik_google_auth_test/google_auth_test.dart';
import 'package:test/test.dart';

void main() {
  group('io', () {
    runGoogleAuthTests(
      service: tekartikGoogleAuthServiceIo,
      options: TekartikGoogleAuthOptionsIo(
        clientId: 'mock_client_id',
        clientSecret: 'mock_client_secret',
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
        // Nothing is read from or written to the disk.
        credentialsPersistence: TekartikFirebasePersistenceMemory(),
      ),
    );
  });
}
```

### Shared suite on a custom implementation

```dart
import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:tekartik_google_auth_test/google_auth_test.dart';
import 'package:test/test.dart';

/// Minimal in memory implementation, to run the common tests on.
class MockGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  MockGoogleAuth({required this.service, required this.options});

  static const mockUser = TekartikGoogleAuthUser(
    id: 'mock_id',
    email: 'mock@example.com',
  );

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    currentUserAdd(mockUser);
    return currentUser;
  }

  /// Nothing saved, nothing to restore.
  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async => currentUser;

  @override
  Future<void> signOut() async => currentUserAdd(null);

  @override
  Future<AuthClient?> getClient() async => null;
}

class MockGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'mock';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) =>
      getInstance(options, () => MockGoogleAuth(service: this, options: options));
}

void main() {
  group('mock', () {
    runGoogleAuthTests(
      service: MockGoogleAuthService(),
      options: TekartikGoogleAuthOptions(
        clientId: 'mock_client_id',
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      ),
    );
  });
}
```

### Auth level tests on an already signed in auth

```dart
import 'package:tekartik_google_auth_test/google_auth_test.dart';
import 'package:test/test.dart';

/// End to end check of a real sign in: the auth is left untouched (not signed
/// in, not closed) by the suite. Sign in by hand (dev menu) before running it.
void defineSignedInTests(TekartikGoogleAuth auth) {
  group('signed in', () {
    runGoogleAuthAuthTests(auth: auth);

    test('has a user', () async {
      await auth.authReady;
      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUser?.email, isNotNull);
    });
  });
}
```

### Console dev menu, client id asked once

```dart
// Console menu, run with:
//   dart run example/google_auth_io_menu_example.dart
//
// The client id/secret are asked once in the `kv` menu (they are saved as
// vars), they must come from a "Desktop app" OAuth client.
import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:tekartik_google_auth_test/menu/google_auth_client_menu.dart';

var clientIdKv = 'google_auth_io_menu_example.client_id'.kvFromVar();
var clientSecretKv = 'google_auth_io_menu_example.client_secret'.kvFromVar();

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    var auth = tekartikGoogleAuthServiceIo.auth(
      TekartikGoogleAuthOptionsIo(
        clientId: clientIdKv.value ?? 'missing_client_id',
        clientSecret: clientSecretKv.value,
        // Minimum scope needed to read the user info
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      ),
    );
    tekartikGoogleAuthMainMenu(
      context: TekartikGoogleAuthMainMenuContext(auth: auth),
    );
    keyValuesMenu('kv', [clientIdKv, clientSecretKv]);
  });
}
```
