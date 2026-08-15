# tekartik_google_auth_test

Common tests and dev menu for the
[`tekartik_google_auth`](../google_auth) implementations
(`tekartik_google_auth_flutter`, `tekartik_google_auth_io`), the equivalent of
`tekartik_firebase_auth_test` for google auth.

## Getting started

```yaml
dev_dependencies:
  tekartik_google_auth_test:
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_test
    version: '>=0.1.0'
```

## Menu

`tekartikGoogleAuthMainMenu()` is a
[`tekartik_app_dev_menu`](https://github.com/tekartik/test_menu.dart) menu to
play with a `TekartikGoogleAuth` from the console (or the browser):

```dart
import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:tekartik_google_auth_test/menu/google_auth_client_menu.dart';

Future<void> main(List<String> args) async {
  var auth = tekartikGoogleAuthServiceIo.auth(
    TekartikGoogleAuthOptionsIo(
      clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
      clientSecret: 'YOUR_CLIENT_SECRET',
      scopes: [tekartikGoogleAuthUserInfoProfileScope],
    ),
  );
  await mainMenu(args, () {
    tekartikGoogleAuthMainMenu(
      context: TekartikGoogleAuthMainMenuContext(auth: auth),
    );
  });
}
```

* `signIn`: `service` (name and options), `current user`, `register`/`cancel
  on current user` (the `onCurrentUser` stream), `authReady`, `signIn`,
  `signInSilently`, `signOut`.
* `client`: `getClient` (token expiry, scopes, refresh token) and
  `getAuthHeaders`.

See
[example/google_auth_io_menu_example.dart](example/google_auth_io_menu_example.dart),
a ready to run console menu asking the client id/secret in its `kv` menu:

```
dart run example/google_auth_io_menu_example.dart
```

## Tests

`runGoogleAuthTests()` runs the common tests of an implementation - nothing is
interactive, `signIn()` (which shows a consent ui) is never called:

```dart
import 'package:tekartik_google_auth_test/google_auth_test.dart';

void main() {
  runGoogleAuthTests(
    service: tekartikGoogleAuthServiceIo,
    options: TekartikGoogleAuthOptionsIo(
      clientId: 'mock_client_id',
      clientSecret: 'mock_client_secret',
      scopes: [tekartikGoogleAuthUserInfoProfileScope],
      // Nothing is read from or written to the disk
      credentialsPersistence: TekartikFirebasePersistenceMemory(),
    ),
  );
}
```

`runGoogleAuthAuthTests()` does the same on an existing `TekartikGoogleAuth`,
signed in or not.
