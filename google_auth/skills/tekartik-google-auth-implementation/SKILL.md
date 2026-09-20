---
name: tekartik-google-auth-implementation
description: >-
  Use when writing a new backend/platform implementation or an in memory fake
  of the tekartik_google_auth api: the package:tekartik_google_auth/
  google_auth_impl.dart import, TekartikGoogleAuthMixin,
  TekartikGoogleAuthServiceMixin, getInstance(), currentUserAdd(),
  currentUserClose(), restoreCurrentUser(), authReady, supportsSignInSilently,
  supportsServiceAccount, authViaServiceAccount(), tekartikGoogleAuthLog and
  debugTekartikGoogleAuthService. Also use to fake the auth in a unit test.
---

# Writing a TekartikGoogleAuth implementation (tekartik_google_auth)

`tekartik_google_auth` ships the two mixins every backend is built on
(`tekartik_google_auth_flutter`, `tekartik_google_auth_io`). The same mixins
give the shortest in memory fake for a unit test.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_google_auth:
      git:
        url: https://github.com/tekartik/google_auth.dart
        path: google_auth
      version: '>=0.4.0'
  ```
* Import `package:tekartik_google_auth/google_auth_impl.dart`, **not**
  `google_auth.dart`: it re-exports the whole public api and adds
  `TekartikGoogleAuthMixin`, `TekartikGoogleAuthServiceMixin` and
  `tekartikGoogleAuthLog`. Application code keeps importing `google_auth.dart`,
  see the sibling `tekartik-google-auth-api` skill.
* The auth object: `class MyAuth with TekartikGoogleAuthMixin`. The mixin
  implements `TekartikGoogleAuth`, provides `clientId`, `scopes`,
  `currentUser`, `isSignedIn`, `onCurrentUser`, `authReady`,
  `getAuthHeaders()` (derived from `getClient()`), `close()` and `toString()`.
  You must provide: `service`, `options`, `signIn()`, `signInSilently()`,
  `signOut()` and `getClient()`.
* Publish every state change with `currentUserAdd(user)` (`@protected`), never
  by assigning a field: it updates `currentUser` and notifies `onCurrentUser`.
  Publishing the same user twice is a no-op, but the very first value is
  always published, even a `null` one, so listeners can tell "signed out" from
  "not resolved yet". Call it with `null` in `signOut()`.
* `restoreCurrentUser()` (`@protected`) runs **once**, on the first
  `onCurrentUser` listen or `authReady` await, and defaults to
  `signInSilently()` when `service.supportsSignInSilently` is true. Override
  it to return `null` when the implementation keeps no saved credentials, so
  that merely listening never triggers a network call or a consent screen.
  Errors thrown there are caught and logged, and a value (possibly `null`) is
  always published afterwards.
* Override `close()` to release the backend resources (http client, sign in
  plugin), then `await super.close()`, which completes `authReady` with
  `false` and calls `currentUserClose()`. Do not call `currentUserAdd()` after
  closing (it is guarded, but the event is dropped).
* Build `TekartikGoogleAuthUser(id:, email:, displayName:, photoUrl:)` from
  the backend account; `id` is the google `sub`. `email`/`displayName`/
  `photoUrl` stay `null` unless the matching scope was requested. It is a
  value object (equality on all four fields), which is what makes the
  "no duplicate event" rule work.
* The service object: `class MyAuthService with TekartikGoogleAuthServiceMixin`
  provides `supportsSignInSilently` (default `true`),
  `supportsServiceAccount` (default `false`), a throwing
  `authViaServiceAccount()` and `getInstance(options, create)`, which caches
  one auth per equal `TekartikGoogleAuthOptions`. You must provide `name`
  (`'flutter'`, `'io'`, ...) and `auth(options)`, implemented as
  `getInstance(options, () => MyAuth(...))`.
* Expose the service as a lazily created global
  (`var tekartikGoogleAuthServiceMine = MyAuthService();` or a
  `late final` behind a getter), the way `tekartikGoogleAuthServiceIo` and
  `tekartikGoogleAuthServiceFlutter` do.
* Accepting extra settings: subclass `TekartikGoogleAuthOptions` (like
  `TekartikGoogleAuthOptionsIo`) and type-check it in `auth()`; an unknown
  subclass must still work as the base type. Keep `==`/`hashCode` consistent,
  the instance cache depends on it (the base `==` already compares
  `runtimeType`).
* Support service accounts by overriding `supportsServiceAccount => true` and
  `authViaServiceAccount(serviceAccount, {scopes, impersonatedUser})`;
  `serviceAccount` is the downloaded json as a `Map` or as an encoded
  `String`. Only do this off-device (io), a shipped app must not carry a
  private key.
* Trace with `tekartikGoogleAuthLog('...')`, which prints only when
  `debugTekartikGoogleAuthService` is true. No `print` in an implementation.
* Testing: run the shared suite from `tekartik_google_auth_test` against the
  new service, and keep an in memory fake (below) for the tests of code that
  merely consumes a `TekartikGoogleAuth`.
* Anti-patterns: exposing `Subject`/`StreamController` instead of
  `currentUserAdd`; creating a new auth object per call instead of
  `getInstance`; signing in from `restoreCurrentUser()`; overriding
  `getAuthHeaders()` when `getClient()` already works.

## Examples

### In memory fake, for unit tests

```dart
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Minimal in memory implementation, enough to test consumer code.
class MockGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  MockGoogleAuth({required this.service, required this.options});

  static const mockUser = TekartikGoogleAuthUser(
    id: 'mock_id',
    email: 'mock@example.com',
    displayName: 'Mock User',
  );

  /// Stands in for the saved credentials, what [signInSilently] restores.
  TekartikGoogleAuthUser? savedUser;

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    savedUser = mockUser;
    currentUserAdd(mockUser);
    return currentUser;
  }

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async {
    var savedUser = this.savedUser;
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

class MockGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'mock';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) => getInstance(
    options,
    () => MockGoogleAuth(service: this, options: options),
  );
}

/// The global, like `tekartikGoogleAuthServiceIo`.
final tekartikGoogleAuthServiceMock = MockGoogleAuthService();
```

### A real backend: wrapping credentials into the mixin

```dart
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Whatever the platform sdk returns on a successful sign in.
class MySignInResult {
  final String accountId;
  final String? email;
  final AuthClient client;

  MySignInResult({required this.accountId, this.email, required this.client});
}

class MyGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  MyGoogleAuth({required this.service, required this.options});

  AuthClient? _client;

  Future<MySignInResult?> _platformSignIn({required bool silentOnly}) async {
    // Call the platform sdk here with options.clientId/options.scopes.
    tekartikGoogleAuthLog('platform sign in (silentOnly: $silentOnly)');
    return null;
  }

  TekartikGoogleAuthUser? _handle(MySignInResult? result) {
    if (result == null) {
      return null;
    }
    _client = result.client;
    currentUserAdd(
      TekartikGoogleAuthUser(id: result.accountId, email: result.email),
    );
    return currentUser;
  }

  @override
  Future<TekartikGoogleAuthUser?> signIn() async =>
      _handle(await _platformSignIn(silentOnly: false));

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async =>
      _handle(await _platformSignIn(silentOnly: true));

  @override
  Future<void> signOut() async {
    _client?.close();
    _client = null;
    currentUserAdd(null);
  }

  @override
  Future<AuthClient?> getClient() async => _client;

  @override
  Future<void> close() async {
    _client?.close();
    _client = null;
    await super.close();
  }
}

class MyGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'my_backend';

  @override
  bool get supportsSignInSilently => true;

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) =>
      getInstance(options, () => MyGoogleAuth(service: this, options: options));
}
```

### Opting out of the automatic restore

```dart
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// A backend with no saved credentials: listening to `onCurrentUser` must not
/// pop a consent screen, so the restore resolves to null instead of signing
/// in silently.
mixin NoRestoreGoogleAuthMixin on TekartikGoogleAuthMixin {
  @override
  Future<TekartikGoogleAuthUser?> restoreCurrentUser() async {
    tekartikGoogleAuthLog('nothing to restore');
    return null;
  }
}
```
