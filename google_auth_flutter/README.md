# tekartik_google_auth_flutter

Flutter implementation of [`tekartik_google_auth`](../google_auth) (Google
sign in, an authenticated client for the googleapis), based on
`google_sign_in`, with the web "Sign in with Google" rendered button.

Runs on Android, iOS and web (the `google_sign_in` 6.x platforms; desktop
needs its own google_sign_in implementation).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_google_auth_flutter:
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_flutter
```

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

/// One auth for the app: equal options give the same instance.
TekartikGoogleAuthFlutter get appGoogleAuth =>
    tekartikGoogleAuthServiceFlutter.auth(
          TekartikGoogleAuthOptions(
            clientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
            scopes: [
              tekartikGoogleAuthEmailScope,
              tekartikGoogleAuthProfileScope,
            ],
          ),
        )
        as TekartikGoogleAuthFlutter;

class SignInWidget extends StatelessWidget {
  const SignInWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var auth = appGoogleAuth;
    // The first listen restores the previous sign in silently.
    return StreamBuilder<TekartikGoogleAuthUser?>(
      stream: auth.onCurrentUser,
      builder: (context, snapshot) {
        var user = snapshot.data;
        if (user == null) {
          // The GSI button on web, an ElevatedButton elsewhere.
          return TekartikGoogleSignInRenderButton(auth: auth);
        }
        return Text(user.email ?? 'signed in');
      },
    );
  }
}

/// An authenticated http client for any googleapis api (owned by the auth,
/// do not close it), null when not signed in.
Future<String?> userInfo() async {
  var client = await appGoogleAuth.getClient();
  var response = await client?.get(
    Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
  );
  return response?.body;
}
```

The whole `TekartikGoogleAuth` api is available (`signIn`, `signInSilently`,
`signOut`, `currentUser`, `onCurrentUser`, `authReady`, `getClient`,
`getAuthHeaders`...), plus:

* `googleSignIn`: the underlying `GoogleSignIn` (incremental scopes with
  `requestScopes`/`canAccessScopes`).
* `webSignInButton()`: the web only GSI rendered button (throws elsewhere).
* `TekartikGoogleSignInRenderButton(auth: auth)`: the GSI button on web, a
  plain `ElevatedButton` elsewhere.
* `tekartikGoogleAuthInitializeGsi(clientId: ...)`: web only, direct GSI
  initialization for a custom button.

## Platform configuration

* Android and iOS: the native configuration (OAuth client of the app,
  `google-services.json`, `GoogleService-Info.plist` and its URL scheme).
* Web: the web client id in `web/index.html`:

  ```html
  <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
  ```

  then in the [Google Cloud Console](https://console.cloud.google.com/),
  OAuth 2.0 credentials of type Web application, add every authorized
  JavaScript origin you serve from (e.g. `http://localhost:8080`, and run
  `flutter run -d chrome --web-port 8080`).

## Common pitfalls

* `signIn()` and `signInSilently()` never throw: they return null when
  cancelled or failed (set `debugTekartikGoogleAuthService = true` to see
  why; the log never prints a token nor the server auth code).
* On web, `signIn()` is deprecated by GSI: render the button.
* Never put a client secret in an app.
* Adding a scope to the options gives another auth instance: request extra
  scopes with `googleSignIn.requestScopes`.
* `close()` is for the end of the app; in a widget, cancel your subscription.

The [tekartik-google-auth-flutter-setup skill](skills/tekartik-google-auth-flutter-setup/SKILL.md)
has more examples.
