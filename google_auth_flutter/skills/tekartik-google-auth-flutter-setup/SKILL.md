---
name: tekartik-google-auth-flutter-setup
description: >-
  Use when adding google sign in to a flutter app (web, android, ios, desktop)
  with tekartik_google_auth_flutter: tekartikGoogleAuthServiceFlutter,
  TekartikGoogleAuthFlutter, TekartikGoogleAuthServiceFlutter,
  TekartikGoogleSignInRenderButton, webSignInButton(),
  tekartikGoogleAuthInitializeGsi(), the underlying google_sign_in
  (googleSignIn, requestScopes, canAccessScopes), getClient() for googleapis,
  the web/index.html google-signin-client_id meta tag and the
  package:tekartik_google_auth_flutter/google_auth_flutter.dart import.
---

# tekartik_google_auth_flutter: google sign in for flutter

`tekartik_google_auth_flutter` implements `tekartik_google_auth` with
`google_sign_in` (plus `extension_google_sign_in_as_googleapis_auth` for the
authenticated client), and adds the GSI "Sign in with Google" rendered button
on web. App code keeps talking to the common `TekartikGoogleAuth` api.

## Guidelines

* Dependency (git, not on pub.dev). It re-exports `tekartik_google_auth`, so
  the app does not need to depend on it separately:
  ```yaml
  dependencies:
    tekartik_google_auth_flutter:
      git:
        url: https://github.com/tekartik/google_auth.dart
        path: google_auth_flutter
      version: '>=0.3.0'
  ```
* Import `package:tekartik_google_auth_flutter/google_auth_flutter.dart`: the
  whole common api (`TekartikGoogleAuth`, `TekartikGoogleAuthOptions`,
  `TekartikGoogleAuthUser`, the scope constants) plus
  `tekartikGoogleAuthServiceFlutter`, `TekartikGoogleAuthFlutter`,
  `TekartikGoogleAuthServiceFlutter`, `TekartikGoogleSignInRenderButton` and
  `tekartikGoogleAuthInitializeGsi`. See the `tekartik-google-auth-api` skill
  for the common api itself.
* Entry point: the `tekartikGoogleAuthServiceFlutter` global (`name ==
  'flutter'`). `tekartikGoogleAuthServiceFlutter.auth(options)` returns the
  same instance for equal `TekartikGoogleAuthOptions`, so a getter rebuilding
  the options is fine and gives one auth for the whole app. Cast the result
  `as TekartikGoogleAuthFlutter` to reach `googleSignIn` or
  `webSignInButton()`; the widgets only need `TekartikGoogleAuth`.
* Options: plain `TekartikGoogleAuthOptions(clientId:, scopes:)`. There is no
  flutter-specific options class, and `clientSecret` is unused here (never
  ship one in an app). `clientId` is the **web** OAuth client id on web; on
  android/ios the native configuration (SHA-1 client, plist/URL scheme) is the
  one that counts, so keep the id in a config/flavor file rather than inline.
* The constructor creates `GoogleSignIn(clientId:, scopes:)` and subscribes to
  `onCurrentUserChanged`, so `currentUser`/`onCurrentUser` also follow a sign
  in made directly through `googleSignIn` or through the GSI button.
* `signIn()` and `signInSilently()` **never throw**: a cancelled or failed
  sign in is logged (`debugTekartikGoogleAuthService = true` to see it) and
  returns `null`. Always null-check.
* On **web**, `signIn()` is deprecated in GSI and may do nothing: render the
  button instead. `TekartikGoogleSignInRenderButton(auth: auth)` is the
  portable widget - the GSI rendered button on web, an
  `ElevatedButton.icon` calling `signIn()` elsewhere. `auth.webSignInButton()`
  is the raw web-only widget and throws a `StateError` off the web.
  `getClient()` only tries `signInSilently()` on web for the same reason.
* Web configuration: add the client id to `web/index.html`
  ```html
  <meta name="google-signin-client_id"
        content="my_web_client_id.apps.googleusercontent.com">
  ```
  and register every origin you serve from (`http://localhost:8080`, ...) in
  the *Web application* OAuth client "authorized JavaScript origins". Use
  `flutter run -d chrome --web-port 8080` so the origin is stable.
  `tekartikGoogleAuthInitializeGsi(clientId:)` loads and initializes the GSI
  sdk (FedCM One Tap) for code driving `google_identity_services_web`
  directly; it is web only and throws a `StateError` elsewhere.
* `getClient()` returns an `AuthClient` built by
  `extension_google_sign_in_as_googleapis_auth`, ready for any `googleapis`
  api; it signs in silently first (interactively off the web) and requests the
  missing scopes. It returns `null` when the user is not signed in. The auth
  owns it: `signOut()` and `close()` drop it, never close it yourself.
* Extra scopes: `auth.googleSignIn` exposes the underlying `GoogleSignIn` for
  `requestScopes([...])`/`canAccessScopes([...])` (incremental
  authorization), `disconnect()` or a platform specific call. Not every
  platform implements `canAccessScopes`, so treat a failure as "request it".
  Adding a scope to the options instead creates a **different** auth instance.
* `close()` is for the end of the app: the service caches one auth per equal
  options, and a closed auth stays in that cache with a closed
  `onCurrentUser`. In a widget, cancel your subscription in `dispose()` and
  leave the auth open.
* Tests: `flutter test` with `TestWidgetsFlutterBinding.ensureInitialized()`.
  Without a platform plugin only the wiring is testable (the service global,
  the instance cache, `auth.googleSignIn.scopes`); use a fake
  `TekartikGoogleAuth` (see `tekartik_google_auth`'s implementation skill) for
  widget tests, and the shared suite/dev menu of `tekartik_google_auth_test`
  on a device.
* Anti-patterns: calling `signIn()` on web instead of rendering the button;
  putting a client secret in the options; creating a `GoogleSignIn` of your
  own next to the auth; closing the `AuthClient`; using
  `authViaServiceAccount()` here (unsupported, it throws `UnsupportedError`,
  it is io only).

## Examples

### Sign in screen following the current user

```dart
import 'package:flutter/material.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

/// One auth for the whole app: equal options return the same instance.
TekartikGoogleAuthFlutter get appGoogleAuth =>
    tekartikGoogleAuthServiceFlutter.auth(
          TekartikGoogleAuthOptions(
            clientId: 'my_web_client_id.apps.googleusercontent.com',
            scopes: [
              tekartikGoogleAuthEmailScope,
              tekartikGoogleAuthProfileScope,
            ],
          ),
        )
        as TekartikGoogleAuthFlutter;

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var auth = appGoogleAuth;
    return Scaffold(
      body: Center(
        // The first listen restores the previous sign in silently.
        child: StreamBuilder<TekartikGoogleAuthUser?>(
          stream: auth.onCurrentUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            var user = snapshot.data;
            if (user == null) {
              // GSI button on web, ElevatedButton elsewhere.
              return TekartikGoogleSignInRenderButton(auth: auth);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.photoUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.photoUrl!),
                  ),
                Text(user.displayName ?? user.email ?? 'signed in'),
                TextButton(
                  onPressed: () {
                    auth.signOut();
                  },
                  child: const Text('Sign out'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

### App state listening to the auth

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

class AuthStatus extends StatefulWidget {
  final TekartikGoogleAuth auth;

  const AuthStatus({super.key, required this.auth});

  @override
  State<AuthStatus> createState() => _AuthStatusState();
}

class _AuthStatusState extends State<AuthStatus> {
  StreamSubscription<TekartikGoogleAuthUser?>? _subscription;
  TekartikGoogleAuthUser? _user;

  @override
  void initState() {
    super.initState();
    _subscription = widget.auth.onCurrentUser.listen((user) {
      setState(() => _user = user);
    });
  }

  @override
  void dispose() {
    // Cancel the subscription, but leave the shared auth open.
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _signIn() async {
    // Returns null when cancelled or failed, it never throws.
    if (await widget.auth.signIn() == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sign in cancelled')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = _user;
    if (user == null) {
      return TextButton(onPressed: _signIn, child: const Text('Sign in'));
    }
    return Text(user.email ?? 'signed in');
  }
}
```

### Calling a google api with the authenticated client

```dart
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

/// The client is an http.Client, ready for any googleapis api object; it is
/// owned by [auth], do not close it.
Future<String?> fetchUserInfo(TekartikGoogleAuth auth) async {
  var client = await auth.getClient();
  if (client == null) {
    return null; // not signed in
  }
  var response = await client.get(
    Uri.parse('https://www.googleapis.com/oauth2/v3/userinfo'),
  );
  return response.body;
}
```

### Asking for a scope only when the feature is used

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

/// Incremental authorization through the underlying google_sign_in, so the
/// auth instance (and its options) stays the same.
Future<bool> ensureDriveScope(TekartikGoogleAuthFlutter auth) async {
  GoogleSignIn googleSignIn = auth.googleSignIn;
  try {
    if (await googleSignIn.canAccessScopes([driveFileScope])) {
      return true;
    }
  } catch (_) {
    // Not implemented on every platform: just request it.
  }
  return await googleSignIn.requestScopes([driveFileScope]);
}
```

### Web only: initializing GSI yourself

```dart
import 'package:flutter/foundation.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

/// Web only (throws a StateError elsewhere), for a custom
/// "Sign In With Google" button built on google_identity_services_web.
/// The common path is TekartikGoogleSignInRenderButton, which needs none of
/// this.
Future<void> initializeGsi() async {
  if (!kIsWeb) {
    return;
  }
  await tekartikGoogleAuthInitializeGsi(
    clientId: 'my_web_client_id.apps.googleusercontent.com',
  );
}
```
