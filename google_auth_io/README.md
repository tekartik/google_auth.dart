# tekartik_google_auth_io

Io (console/desktop, **no flutter**) implementation of
[`tekartik_google_auth`](../google_auth), on top of the
`googleapis_auth` loopback consent flow.

## Getting started

```yaml
dependencies:
  tekartik_google_auth_io:
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_io
    version: '>=0.5.0'
```

## Usage

The client id/secret are kept in RAM, nothing is read from a
`client_secret.json` / `.local/client_id.yaml` file:

```dart
import 'package:tekartik_google_auth_io/google_auth_io.dart';

var auth = tekartikGoogleAuthServiceIo.auth(
  TekartikGoogleAuthOptionsIo(
    clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
    clientSecret: 'YOUR_CLIENT_SECRET',
    projectId: 'your-project',
    // Minimum scope needed to read the user info
    scopes: [tekartikGoogleAuthUserInfoProfileScope],
  ),
);

auth.onCurrentUser.listen((user) => print('current user: $user'));

await auth.signIn();

// Authenticated client, ready for any googleapis api, owned by [auth]
var client = await auth.getClient();
```

`tekartikGoogleAuthServiceIo.auth()` returns the same instance for equal
options. `TekartikGoogleAuthOptionsIo` adds `credentialsPersistence`/`credentialsKey`
to the common `TekartikGoogleAuthOptions` - the same names as
`GoogleAuthProviderRestIo` in `tekartik_firebase_auth_rest`.

## Login flow

`signIn()` opens a local loopback http server, then writes the consent url
**and launches it** in the OS browser:

```
Please go to the following URL and grant access:
  => https://accounts.google.com/o/oauth2/v2/auth?client_id=...
```

Override it with `TekartikGoogleAuthOptionsIo.promptUserConsent` - a flutter
app should, so the url goes through `url_launcher`:

```dart
import 'package:tekartik_app_url_launcher_flutter/web_launch_uri.dart';

Future<void> flutterPromptUserConsent(String url) async {
  print('  => $url');
  webLaunchUri(Uri.parse(url));
}

TekartikGoogleAuthOptionsIo(
  ...,
  promptUserConsent: flutterPromptUserConsent,
);
```

The bare `dart:io` default is a best effort `Process.start` of `xdg-open`
(linux) / `open` (macOS) / `start` (windows); the url is always written too, so
it can be copied if the launch fails.

## Saved credentials

The access/refresh token is cached in a `KvStore` (the generic string
key/value interface of
[`tekartik_prefs`](https://github.com/tekartik/prefs.dart/tree/main/prefs))
and reused:

* `signInSilently()` only restores the cached credentials, it never prompts
  (it returns null when `hasSavedCredentials` is false).
* `signOut()` forgets the cached credentials.
* Credentials saved for other scopes, or without a refresh token, are ignored:
  they cannot be restored, so a new consent is asked instead.

By default they go to `.local/access_credentials.yaml`, relative to the current
directory - the json content of `tekartik_io_auth_utils`, so an existing file is
still read. Any `KvStore` works, including a `PrefsLight` from
[`tekartik_prefs`](https://github.com/tekartik/prefs.dart) and the
implementations of
[`tekartik_firebase_persistence`](https://github.com/tekartik/firebase.dart/tree/master/firebase_persistence):

```dart
TekartikGoogleAuthOptionsIo(
  ...,
  // Anywhere else on the file system
  credentialsPersistence:
      TekartikFirebasePersistenceFile(directoryPath: '.local/my_app'),
  // Or a database, or web local storage, or memory for a sign in that must
  // not survive the process:
  // credentialsPersistence:
  //     TekartikFirebasePersistenceSdb(sdbFactory: sdbFactoryIo),
  // credentialsPersistence: TekartikFirebasePersistenceMemory(),

  // One key per account, to keep several sign ins side by side
  credentialsKey: 'access_credentials_dev.yaml',
);
```

## OAuth client requirement

The loopback flow binds a **random** local port
(`redirect_uri=http://localhost:<random>`), which google only accepts for a
**Desktop app** OAuth client. A *Web application* client rejects it with
`redirect_uri_mismatch`.

## Example

See [example/google_auth_io_example.dart](example/google_auth_io_example.dart).
