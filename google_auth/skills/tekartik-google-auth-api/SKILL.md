---
name: tekartik-google-auth-api
description: >-
  Use when application code signs in with google and calls google apis through
  the platform agnostic tekartik_google_auth api: TekartikGoogleAuthService,
  TekartikGoogleAuthOptions, TekartikGoogleAuth, TekartikGoogleAuthUser,
  auth(), signIn(), signInSilently(), signOut(), currentUser, onCurrentUser,
  authReady, getClient() (an AuthClient for googleapis), getAuthHeaders(),
  authViaServiceAccount(), the tekartikGoogleAuthEmailScope /
  tekartikGoogleAuthProfileScope / tekartikGoogleAuthUserInfoProfileScope
  scope constants, debugTekartikGoogleAuthService and the
  package:tekartik_google_auth/google_auth.dart import.
---

# Google auth, the common api (tekartik_google_auth)

`tekartik_google_auth` is the **dart only** base of the google auth stack: it
defines the interfaces and the user model, and holds no platform code. Write
application code against this package and let `main` (or a flavor file) pick
the implementation, `tekartik_google_auth_flutter` or `tekartik_google_auth_io`.

## Guidelines

* Dependency (git, not on pub.dev). Applications depend on an implementation
  too, and only that implementation brings a working service object:
  ```yaml
  dependencies:
    tekartik_google_auth:
      git:
        url: https://github.com/tekartik/google_auth.dart
        path: google_auth
      version: '>=0.4.0'
  ```
* Import `package:tekartik_google_auth/google_auth.dart`. It re-exports
  `AuthClient` from `googleapis_auth`, so shared code never needs to import
  `googleapis_auth` itself. `google_auth_impl.dart` is for implementers only,
  see the sibling `tekartik-google-auth-implementation` skill.
* The shape mirrors `tekartik_firebase_auth`: a global
  `TekartikGoogleAuthService` (`tekartikGoogleAuthServiceIo`,
  `tekartikGoogleAuthServiceFlutter`) creates and owns the
  `TekartikGoogleAuth` objects. Pass the service (or the auth) around instead
  of importing an implementation in shared code.
* `service.auth(options)` returns the instance for these
  `TekartikGoogleAuthOptions` and **reuses the same instance for equal
  options**: build the options once, calling `auth()` again with equal options
  is cheap and gives back the same object, not a second session.
* `TekartikGoogleAuthOptions(clientId:, clientSecret:, projectId:, scopes:)`:
  `clientId` is required, `clientSecret` is only used by the io/console flow,
  `projectId` is informative. `scopes` defaults to an empty list and is stored
  unmodifiable; use `tekartikGoogleAuthEmailScope` (`email`),
  `tekartikGoogleAuthProfileScope` (`profile`) and
  `tekartikGoogleAuthUserInfoProfileScope`
  (`https://www.googleapis.com/auth/userinfo.profile`) rather than literals.
  Options compare by value, so a different scope list means a different auth
  instance. `toString()` masks the secret.
* Never hardcode a real client id or secret in committed source: read them
  from a config file, `--dart-define`, or a local `.local/` json.
* Getting the user, in order of preference:
  * `await auth.onCurrentUser.first` - the first listen triggers a silent
    restore, so this resolves to the restored user or `null`, it does not
    block until the next sign in;
  * `await auth.authReady` - same restore without listening, then read
    `auth.currentUser` / `auth.isSignedIn`; it resolves to `false` when the
    auth was closed before the restore finished;
  * `auth.currentUser` alone is `null` both when signed out **and** when the
    restore has not run yet, so only read it after one of the above.
* `onCurrentUser` is a broadcast stream that replays the current value to a
  late listener and emits on every change; publishing the same user twice
  sends no event. Cancel your subscription when the widget/state goes away.
* `signIn()` shows the platform UI/consent and returns `null` when it failed
  or was cancelled - always null-check it. `signInSilently()` only restores
  saved credentials (`null` when there is nothing to restore) and is a no-op
  on services with `supportsSignInSilently == false`. `signOut()` forgets the
  saved credentials and emits `null`.
* `getClient()` returns an `AuthClient` (an `http.Client`) ready to be given
  to a `googleapis` api object, or `null` when signed out. The auth object
  owns it: do not `close()` it yourself, `auth.close()` does. Use
  `getAuthHeaders()` (`Authorization: Bearer ...` + `Content-Type`) only for
  raw http calls you make with your own client.
* `service.authViaServiceAccount(serviceAccountJsonMapOrString, scopes:,
  impersonatedUser:)` authenticates as a service account instead of a user,
  and is only supported when `service.supportsServiceAccount` is `true` (io
  only); the others throw `UnsupportedError`. Guard it with the flag.
* `await auth.close()` when done (end of a cli tool, disposal of the owning
  state object): it closes `onCurrentUser` and the underlying client.
* Set `debugTekartikGoogleAuthService = true` to trace the auth flow on the
  console.
* Anti-patterns: importing `package:googleapis_auth` or an implementation
  package in shared code; creating a new `TekartikGoogleAuthOptions` on every
  build/rebuild and expecting a single instance (equal options do share it,
  but building them in a `build()` method hides it); calling `signIn()`
  without first awaiting the restore, which shows a consent screen to an
  already signed in user; closing the `AuthClient` returned by `getClient()`.
* Tests: this package has no service to test against - write an in memory
  fake with the mixins (see the sibling implementation skill) or run the
  shared suite from `tekartik_google_auth_test`.

## Examples

### Sign in and call a google api

```dart
import 'package:tekartik_google_auth/google_auth.dart';

/// [service] is the platform global: `tekartikGoogleAuthServiceIo` from
/// `package:tekartik_google_auth_io/google_auth_io.dart` or
/// `tekartikGoogleAuthServiceFlutter` from
/// `package:tekartik_google_auth_flutter/google_auth_flutter.dart`.
Future<void> printUserInfo(TekartikGoogleAuthService service) async {
  var auth = service.auth(
    TekartikGoogleAuthOptions(
      clientId: 'my_client_id.apps.googleusercontent.com',
      clientSecret: 'my_client_secret', // io/console flow only
      scopes: [
        tekartikGoogleAuthEmailScope,
        tekartikGoogleAuthUserInfoProfileScope,
      ],
    ),
  );

  // Restores the saved credentials first, only prompts when needed.
  var user = await auth.onCurrentUser.first;
  user ??= await auth.signIn();
  if (user == null) {
    print('sign in cancelled');
    return;
  }
  print('signed in as ${user.email} (${user.displayName})');

  // An AuthClient is an http.Client, ready for any googleapis api object.
  var client = (await auth.getClient())!;
  var response = await client.get(
    Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
  );
  print(response.body);

  // Closes the stream and the client, do not close the client yourself.
  await auth.close();
}
```

### Follow the signed in user

```dart
import 'dart:async';

import 'package:tekartik_google_auth/google_auth.dart';

/// Holds the auth state of the app, one instance for the whole app.
class AppAuthState {
  final TekartikGoogleAuth auth;
  StreamSubscription<TekartikGoogleAuthUser?>? _subscription;

  /// Null while signed out (and until the first restore completes).
  TekartikGoogleAuthUser? user;

  AppAuthState(this.auth);

  /// Listening triggers the initial silent restore.
  void start() {
    _subscription = auth.onCurrentUser.listen((user) {
      this.user = user;
      print(user == null ? 'signed out' : 'signed in: ${user.email}');
    });
  }

  Future<void> signIn() async {
    if (await auth.signIn() == null) {
      print('sign in failed or cancelled');
    }
  }

  Future<void> signOut() => auth.signOut();

  Future<void> dispose() async {
    await _subscription?.cancel();
    await auth.close();
  }
}
```

### Headers for a raw http call, without listening

```dart
import 'package:tekartik_google_auth/google_auth.dart';

/// Signs in if needed, then returns the `Authorization` headers.
Future<Map<String, String>?> authHeaders(TekartikGoogleAuth auth) async {
  // Restores the saved credentials without subscribing to onCurrentUser.
  await auth.authReady;
  if (!auth.isSignedIn) {
    if (await auth.signIn() == null) {
      return null;
    }
  }
  return await auth.getAuthHeaders();
}
```

### Service account, when the implementation supports it

```dart
import 'package:tekartik_google_auth/google_auth.dart';

/// [serviceAccount] is the downloaded service account json, as a `Map` or as
/// the encoded `String`. Never commit it, read it from a local file.
Future<TekartikGoogleAuth?> serviceAccountAuth(
  TekartikGoogleAuthService service,
  Object serviceAccount,
) async {
  if (!service.supportsServiceAccount) {
    // Flutter: no private key in a shipped app.
    return null;
  }
  var auth = service.authViaServiceAccount(
    serviceAccount,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  );
  // No consent step: a signed JWT is exchanged for an access token.
  await auth.signInSilently();
  print('running as ${auth.currentUser?.email}');
  return auth;
}
```
