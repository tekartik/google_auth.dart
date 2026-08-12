# tekartik_google_auth_flutter

Flutter implementation of
[`tekartik_google_auth`](../google_auth), based on
`google_sign_in`, with a web "Sign in with Google" render button.

## Getting started

```yaml
dependencies:
  tekartik_google_auth_flutter:
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_flutter
    version: '>=0.3.0'
```

## Usage

```dart
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

var auth = tekartikGoogleAuthServiceFlutter.auth(
  TekartikGoogleAuthOptions(
    clientId: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
    scopes: [emailScope, profileScope, userInfoProfileScope],
  ),
) as TekartikGoogleAuthFlutter;

auth.onCurrentUser.listen((user) {
  print('user: $user');
});

await auth.signInSilently();

// Authenticated client, ready for any googleapis api
var client = await auth.getClient();
```

`tekartikGoogleAuthServiceFlutter.auth()` returns the same instance for equal
options.

The whole `TekartikGoogleAuth` api is available (`signIn`, `signInSilently`,
`signOut`, `currentUser`, `onCurrentUser`, `getClient`, `getAuthHeaders`, …),
plus:

* `googleSignIn` - the underlying `GoogleSignIn`, for advanced usage.
* `webSignInButton()` - the web only GSI rendered button (throws elsewhere).
* `GoogleSignInRenderButton` - a widget using the GSI button on web and a
  plain `ElevatedButton` elsewhere (`GoogleSignInRenderButton(auth: auth)`).
* `initializeGsi()` - web only direct GSI initialization.

## Web configuration

Configure your OAuth client id in `web/index.html`:

```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Create OAuth 2.0 credentials (Web application)
4. Add the authorized JavaScript origins (e.g. http://localhost:8080)
