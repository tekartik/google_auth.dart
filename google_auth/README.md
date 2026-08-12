# tekartik_google_auth

Common **dart only** base for google authentication. It defines the
`TekartikGoogleAuthService` / `TekartikGoogleAuth` interfaces and the
`GoogleAuthUser` model, and holds the code that does not depend on a platform.

The shape mirrors `tekartik_firebase_auth`: a *service* object creates and owns
the *auth* objects, and the auth object exposes `currentUser`/`onCurrentUser`.

It is not usable on its own, pick an implementation:

| Package | Platform | Backend |
| --- | --- | --- |
| [`tekartik_google_auth_flutter`](../google_auth_flutter) | flutter (web/mobile/desktop) | `google_sign_in` |
| [`tekartik_google_auth_io`](../google_auth_io) | console/desktop, no flutter | `tekartik_io_auth_utils` (loopback consent url) |

## Api

```dart
/// The product level object, available as a global
/// (`tekartikGoogleAuthServiceFlutter`, `tekartikGoogleAuthServiceIo`).
abstract class TekartikGoogleAuthService {
  String get name;
  bool get supportsSignInSilently;

  /// Creates the auth object, reusing the same instance for equal options.
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options);
}

class TekartikGoogleAuthOptions {
  final String clientId;
  final String? clientSecret;
  final String? projectId;
  final List<String> scopes;
}

abstract class TekartikGoogleAuth {
  TekartikGoogleAuthService get service;
  TekartikGoogleAuthOptions get options;
  String get clientId;
  List<String> get scopes;

  GoogleAuthUser? get currentUser;
  bool get isSignedIn;
  Stream<GoogleAuthUser?> get onCurrentUser;

  Future<GoogleAuthUser?> signIn();
  Future<GoogleAuthUser?> signInSilently();
  Future<void> signOut();

  /// Ready to be given to a `googleapis` api object.
  Future<AuthClient?> getClient();
  Future<Map<String, String>?> getAuthHeaders();

  Future<void> close();
}
```

`onCurrentUser` follows the `FirebaseAuth.onCurrentUser` semantics: a broadcast
stream where a newly-added listener immediately receives the current value once
it is known.

## Usage

Application code only imports this package (through an implementation) so it
stays platform agnostic:

```dart
import 'package:tekartik_google_auth/google_auth.dart';

Future<void> printUser(TekartikGoogleAuth auth) async {
  auth.onCurrentUser.listen((user) => print('current user: $user'));

  await auth.signIn();

  // Any googleapis api
  var client = (await auth.getClient())!;
  var person = await PeopleServiceApi(client).people.get('people/me',
      personFields: 'names');
}
```

The auth object owns the client returned by `getClient()`; do not close it
yourself, `close()` does.

Common scope constants are exported: `emailScope` (`email`), `profileScope`
(`profile`) and `userInfoProfileScope`
(`https://www.googleapis.com/auth/userinfo.profile`, the minimum needed to read
the user info).

Set `debugGoogleAuthService = true` to trace what happens.

## Writing an implementation

Import `google_auth_impl.dart` instead of `google_auth.dart`,
then:

* mix in `TekartikGoogleAuthMixin` for the auth object (it handles
  `currentUser`/`onCurrentUser` through `currentUserAdd`, and derives
  `getAuthHeaders` from `getClient`),
* mix in `TekartikGoogleAuthServiceMixin` for the service (it handles the
  per-options instance caching through `getInstance`),
* expose the service as a lazily created global object.
