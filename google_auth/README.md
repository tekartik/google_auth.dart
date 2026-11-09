# tekartik_google_auth

Sign in with Google and call Google APIs with the same Dart code on Flutter
and on the console. This package is the **dart only** common API
(`TekartikGoogleAuthService`, `TekartikGoogleAuth`, `TekartikGoogleAuthUser`);
an implementation does the platform work:

| Package | Platform | Backend |
|---|---|---|
| [`tekartik_google_auth_flutter`](../google_auth_flutter) | Flutter (mobile, web) | `google_sign_in`, web GSI button |
| [`tekartik_google_auth_io`](../google_auth_io) | Dart VM console/desktop, no Flutter | `googleapis_auth` loopback consent, saved credentials, service accounts |

## Getting started

Git packages, not on pub.dev. The app depends on an implementation (it brings
this package along); shared code depends on this package only:

```yaml
dependencies:
  tekartik_google_auth_io: # or tekartik_google_auth_flutter
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_io
```

Shared code takes the service (or the auth) as a parameter:

```dart
import 'package:tekartik_google_auth/google_auth.dart';

/// [service]: tekartikGoogleAuthServiceIo (tekartik_google_auth_io) or
/// tekartikGoogleAuthServiceFlutter (tekartik_google_auth_flutter).
Future<void> printUser(TekartikGoogleAuthService service) async {
  var auth = service.auth(
    TekartikGoogleAuthOptions(
      clientId: 'my_client_id.apps.googleusercontent.com',
      clientSecret: 'my_client_secret', // io only, read it from a file
      scopes: [tekartikGoogleAuthEmailScope],
    ),
  );
  // Restores the saved user (or null), then signs in only if needed.
  var user = await auth.onCurrentUser.first ?? await auth.signIn();
  print(user?.email);
  // An http client for any googleapis api, owned by auth.
  var client = await auth.getClient();
  print(client != null);
  await auth.close();
}
```

Create the OAuth client in the
[Google Cloud Console](https://console.cloud.google.com/apis/credentials): a
**Web application** client for Flutter web, a **Desktop app** client for the
io console flow.

## When to use what

* `service.auth(options)`: the `TekartikGoogleAuth` for these options, the
  same instance for equal options.
* `auth.onCurrentUser`: the current user now and on every change. The first
  listener triggers a silent restore, so `onCurrentUser.first` is the restored
  user or `null`. `auth.authReady` does the same restore without listening.
* `signIn()` (consent UI, `null` when cancelled), `signInSilently()` (saved
  credentials only), `signOut()`.
* `getClient()`: an `AuthClient` (an `http.Client`) for `googleapis`; it signs
  in first when needed (an interactive sign in on io and on Flutter outside
  the web). `getAuthHeaders()`: `Authorization: Bearer ...` for raw calls.
* `service.authViaServiceAccount(json, scopes:)`: a service account instead of
  a user, only when `service.supportsServiceAccount` (io).
* `google_auth_impl.dart`: the mixins to write an implementation or a fake,
  see [example/main.dart](example/main.dart).

## Common pitfalls

* Reading `auth.currentUser` before the restore: it is `null` both when signed
  out and when not restored yet. Await `onCurrentUser.first` or `authReady`.
* Calling `signIn()` without the restore first shows a consent screen to a
  user already signed in.
* Do not close the client of `getClient()`: `auth.close()` does.
* Never commit a client secret or a service account key; never log
  `getAuthHeaders()` (it holds the access token). `options.toString()` masks
  the secret.
* A closed auth does not sign in any more (`authReady` resolves to `false`);
  `service.auth(options)` then gives a new instance.

## More

* Skills: [tekartik-google-auth-api](skills/tekartik-google-auth-api/SKILL.md)
  (application code), [tekartik-google-auth-implementation](skills/tekartik-google-auth-implementation/SKILL.md)
  (new backend or test fake).
* Set `debugTekartikGoogleAuthService = true` to trace the flow.
