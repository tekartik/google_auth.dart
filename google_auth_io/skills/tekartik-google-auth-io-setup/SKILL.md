---
name: tekartik-google-auth-io-setup
description: >-
  Use when signing in to google from a console/desktop dart program (no
  flutter) with tekartik_google_auth_io: tekartikGoogleAuthServiceIo,
  TekartikGoogleAuthOptionsIo, TekartikGoogleAuthIo, the googleapis_auth
  loopback consent flow, promptUserConsent /
  tekartikGoogleAuthIoPromptUserConsent, credentialsPersistence /
  credentialsKey and the KvStore cache (TekartikFirebasePersistenceFile,
  TekartikFirebasePersistenceMemory, TekartikFirebasePersistenceSdb),
  hasSavedCredentials, clientIdMap, authViaServiceAccount /
  TekartikGoogleAuthServiceAccountIo, and the
  package:tekartik_google_auth_io/google_auth_io.dart import.
---

# tekartik_google_auth_io: the console/desktop implementation

`tekartik_google_auth_io` implements `tekartik_google_auth` on the Dart VM with
the `googleapis_auth` loopback consent flow: a local http server catches the
OAuth redirect, and the access/refresh token is cached in a `KvStore`. No
flutter, no `client_secret.json` file: the client id/secret live in RAM.

## Guidelines

* Dependency (git, not on pub.dev). It re-exports `tekartik_google_auth`, so
  a program that only uses the io service needs nothing else:
  ```yaml
  dependencies:
    tekartik_google_auth_io:
      git:
        url: https://github.com/tekartik/google_auth.dart
        path: google_auth_io
      version: '>=0.5.0'
  ```
* Import `package:tekartik_google_auth_io/google_auth_io.dart`. It exports the
  whole common api (`TekartikGoogleAuth`, `TekartikGoogleAuthUser`, the scope
  constants), the `KvStore` interface from `tekartik_prefs`, the
  `TekartikFirebasePersistence*` stores, and the io specific names below.
  Shared code should still be written against `tekartik_google_auth`, see the
  `tekartik-google-auth-api` skill.
* Entry point: the `tekartikGoogleAuthServiceIo` global
  (`TekartikGoogleAuthServiceIo`, `name == 'io'`,
  `supportsSignInSilently == true`, `supportsServiceAccount == true`). Call
  `tekartikGoogleAuthServiceIo.auth(options)`, which returns the same
  `TekartikGoogleAuthIo` for equal options.
* Options: `TekartikGoogleAuthOptionsIo(clientId:, clientSecret:, projectId:,
  scopes:, credentialsPersistence:, credentialsKey:, promptUserConsent:)`.
  Unlike the base class, **`clientSecret` is required** here (the console flow
  needs it; `TekartikGoogleAuthIo.clientSecret` throws a `StateError` when the
  plain base options are used without one). Keep the id/secret out of the
  source: read them from a local file or an environment variable.
* The OAuth client must be a **Desktop app** client. The loopback flow binds a
  random local port (`redirect_uri=http://localhost:<random>`), which a *Web
  application* client rejects with `redirect_uri_mismatch`.
* `signIn()` starts the loopback server and hands the consent url to
  `promptUserConsent`, which defaults to
  `tekartikGoogleAuthIoPromptUserConsent`: it writes the url on stdout **and**
  launches the OS browser (`tekartikGoogleAuthIoLaunchUrl`, a detached
  `xdg-open`/`open`/`cmd /c start`, best effort). Override
  `promptUserConsent` (a `TekartikGoogleAuthPromptUserConsent`, i.e.
  `Future<void> Function(String url)`) for a gui: a flutter app should route
  the url through `tekartik_app_url_launcher_flutter`
  (`webLaunchUri`) instead of `dart:io`.
* `signIn()` rethrows on failure (a closed browser, a refused consent), it
  does not return `null` there; `signInSilently()` swallows the error and
  returns `null`. Wrap the interactive call in a `try`/`catch` for a cli.
* Saved credentials: the token is cached in `credentialsPersistence` (any
  `KvStore`) under `credentialsKey`, defaulting to a
  `TekartikFirebasePersistenceFile` writing `.local/access_credentials.yaml`
  (`tekartikGoogleAuthIoCredentialsKeyDefault`) relative to the current
  directory - the json content of `tekartik_io_auth_utils`, so an existing
  file is still read. Give each account its own `credentialsKey` to keep
  several sign ins side by side; add `.local/` to `.gitignore`.
  * `TekartikFirebasePersistenceFile(directoryPath: '.local/my_app')` for
    another directory, `TekartikFirebasePersistenceMemory()` for a sign in
    that must not survive the process (tests),
    `TekartikFirebasePersistenceSdb(sdbFactory:, dbName:)` for a database,
    `TekartikFirebasePersistenceWebLocalStorage()` on the web. A
    `PrefsLight` from `tekartik_prefs` works too, the auth only uses the
    `KvStore` surface (`getString`/`setString`/`remove`).
  * `auth.hasSavedCredentials` tells whether something is cached;
    `signInSilently()` returns `null` when nothing is. Credentials saved for
    other scopes, or without a refresh token, are ignored and a new consent is
    asked. `signOut()` deletes them.
  * A revoked/expired refresh token (`invalid_grant`) is detected during
    `signIn()`: the dead credentials are dropped and the consent flow runs
    again. `signInSilently()` just fails.
* `getClient()` signs in if needed and returns an auto refreshing
  `AuthClient`, ready for a `googleapis` api object (`Oauth2Api`,
  `DriveApi`, ...). The auth owns it: `auth.close()` closes it, never close it
  yourself. `close()` at the end of the program, otherwise the process may
  hang on the open client.
* Service account (no consent, no cache, no browser):
  `tekartikGoogleAuthServiceIo.authViaServiceAccount(serviceAccountJson,
  scopes: [...], impersonatedUser: ...)` returns a
  `TekartikGoogleAuthServiceAccountIo`. `serviceAccountJson` is the downloaded
  json, as a `Map` or as the encoded `String`. `currentUser` is
  `serviceAccountUser` (the impersonated user with domain-wide delegation,
  otherwise the service account itself), and it stays signed out until
  `signIn()`/`signInSilently()`/`getClient()` is called: listening to
  `onCurrentUser` never mints a token. Never commit the private key.
* `auth.clientIdMap` builds the `client_secret.json` `installed` map in RAM,
  for a tool that needs to hand that format to something else. Nothing in the
  package reads it.
* Trace the flow with `debugTekartikGoogleAuthService = true`.
* Tests: `@TestOn('vm')`, and always pass
  `credentialsPersistence: TekartikFirebasePersistenceMemory()` so nothing
  touches `.local/`. A test must never reach the real consent flow: pass a
  `promptUserConsent` that does nothing, or stop at `hasSavedCredentials`.
  `tekartik_google_auth_test` holds the shared suite and a dev menu.
* Anti-patterns: a Web application OAuth client; committing the client secret
  or a service account json; closing the `AuthClient` from `getClient()`;
  calling `signIn()` before `authReady`/`onCurrentUser.first`, which prompts
  an already signed in user; using this package in a flutter app for mobile
  or web sign in (use `tekartik_google_auth_flutter`; the io flow only fits a
  desktop flutter app, with a custom `promptUserConsent`).

## Examples

### Console sign in and a googleapis call

```dart
// Run with `dart run bin/whoami.dart`.
import 'dart:io';

import 'package:googleapis/oauth2/v2.dart';
import 'package:tekartik_google_auth_io/google_auth_io.dart';

/// Replace with a "Desktop app" OAuth client of your project.
const clientId = 'my_client_id.apps.googleusercontent.com';
const clientSecret = 'my_client_secret';

Future<void> main() async {
  var auth = tekartikGoogleAuthServiceIo.auth(
    TekartikGoogleAuthOptionsIo(
      clientId: clientId,
      clientSecret: clientSecret,
      projectId: 'my-project',
      // Minimum scope needed to read the user info
      scopes: [tekartikGoogleAuthUserInfoProfileScope],
    ),
  );
  auth.onCurrentUser.listen((user) {
    stdout.writeln('current user: $user');
  });
  try {
    // Restores the cached token, or writes/opens the consent url once.
    var user = await auth.onCurrentUser.first;
    user ??= await auth.signIn();

    // Auto refreshing client, owned by the auth object.
    var client = (await auth.getClient())!;
    var info = await Oauth2Api(client).userinfo.get();
    stdout.writeln('${info.email} ${info.name}');
  } catch (e) {
    stderr.writeln('sign in failed: $e');
    exitCode = 1;
  } finally {
    // Closes the client, otherwise the process hangs.
    await auth.close();
  }
}
```

### Where the token is cached, and one sign in per account

```dart
import 'package:tekartik_google_auth_io/google_auth_io.dart';

/// One auth per account name, each with its own cached token file in
/// `.local/my_app/`.
TekartikGoogleAuthIo accountAuth(String account) {
  return tekartikGoogleAuthServiceIo.auth(
        TekartikGoogleAuthOptionsIo(
          clientId: 'my_client_id.apps.googleusercontent.com',
          clientSecret: 'my_client_secret',
          scopes: [
            tekartikGoogleAuthEmailScope,
            tekartikGoogleAuthUserInfoProfileScope,
          ],
          // Default: TekartikFirebasePersistenceFile() writing in `.local`
          credentialsPersistence: TekartikFirebasePersistenceFile(
            directoryPath: '.local/my_app',
          ),
          // Default: tekartikGoogleAuthIoCredentialsKeyDefault
          credentialsKey: 'access_credentials_$account.yaml',
        ),
      )
      as TekartikGoogleAuthIo;
}

/// Signs in without ever prompting, `null` when nothing is cached.
Future<TekartikGoogleAuthUser?> restore(String account) async {
  var auth = accountAuth(account);
  if (!await auth.hasSavedCredentials) {
    return null;
  }
  return await auth.signInSilently();
}
```

### A custom consent prompt

```dart
import 'package:tekartik_google_auth_io/google_auth_io.dart';

/// Shows the url in the app instead of writing it on stdout. A flutter
/// desktop app launches it with `webLaunchUri` from
/// `tekartik_app_url_launcher_flutter`.
Future<void> myPromptUserConsent(String url) async {
  print('open this url to grant access: $url');
}

TekartikGoogleAuth newAuth() => tekartikGoogleAuthServiceIo.auth(
  TekartikGoogleAuthOptionsIo(
    clientId: 'my_client_id.apps.googleusercontent.com',
    clientSecret: 'my_client_secret',
    scopes: [tekartikGoogleAuthUserInfoProfileScope],
    // A TekartikGoogleAuthPromptUserConsent, default:
    // tekartikGoogleAuthIoPromptUserConsent (stdout + OS browser).
    promptUserConsent: myPromptUserConsent,
  ),
);
```

### Service account, for a server or a ci job

```dart
import 'dart:convert';
import 'dart:io';

import 'package:tekartik_google_auth_io/google_auth_io.dart';

/// Reads the downloaded service account json, kept out of the repository.
Future<void> main() async {
  var serviceAccount =
      jsonDecode(await File('.local/service_account.json').readAsString())
          as Map<String, Object?>;

  var auth = tekartikGoogleAuthServiceIo.authViaServiceAccount(
    serviceAccount, // the Map or the raw json String
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    // Domain-wide delegation only:
    // impersonatedUser: 'someone@example.com',
  );
  // No consent, no browser: the private key signs a JWT.
  await auth.signInSilently();
  stdout.writeln('running as ${auth.serviceAccountUser.email}');

  var client = (await auth.getClient())!;
  stdout.writeln(client.credentials.accessToken.type);

  await auth.close();
}
```

### Test, without touching the disk

```dart
@TestOn('vm')
library;

import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:test/test.dart';

Future<void> mockPromptUserConsent(String url) async {}

/// Signed out auth, nothing is ever read from or written to the disk.
TekartikGoogleAuthIo newMemoryAuth() =>
    tekartikGoogleAuthServiceIo.auth(
          TekartikGoogleAuthOptionsIo(
            clientId: 'mock_client_id',
            clientSecret: 'mock_client_secret',
            scopes: [tekartikGoogleAuthUserInfoProfileScope],
            credentialsPersistence: TekartikFirebasePersistenceMemory(),
            promptUserConsent: mockPromptUserConsent,
          ),
        )
        as TekartikGoogleAuthIo;

void main() {
  test('signed out, nothing cached', () async {
    var auth = newMemoryAuth();
    expect(await auth.hasSavedCredentials, isFalse);
    // Never prompts: returns null when there is nothing to restore.
    expect(await auth.signInSilently(), isNull);
    expect(await auth.onCurrentUser.first, isNull);
    expect(auth.isSignedIn, isFalse);
    await auth.close();
  });
}
```
