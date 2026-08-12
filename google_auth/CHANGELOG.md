## 0.4.0

* Moved to its own public repository,
  [google_auth.dart](https://github.com/tekartik/google_auth.dart).
* **Breaking**: the package is renamed `tekartik_google_auth` (was
  `tekartik_google_auth_service`), and its libraries `google_auth.dart` /
  `google_auth_impl.dart` (were `google_auth_service.dart` /
  `google_auth_service_impl.dart`). The class names are unchanged.

## 0.3.0

* **Breaking**: `GoogleAuthService` is renamed `TekartikGoogleAuth`, and
  `GoogleAuthServiceBase` `TekartikGoogleAuthMixin`.
* **Breaking**: `onCurrentUserChanged` is renamed `onCurrentUser` and now
  follows the `FirebaseAuth.onCurrentUser` semantics (a new listener
  immediately receives the current value).
* New `TekartikGoogleAuthService` product level object with a single
  `auth(TekartikGoogleAuthOptions)` api, creating/caching the
  `TekartikGoogleAuth` instances, and `TekartikGoogleAuthServiceMixin`.
* New `TekartikGoogleAuthOptions` (`clientId`, `clientSecret`, `projectId`,
  `scopes`) replacing the constructor arguments.

## 0.2.0

* **Breaking**: the package is now dart only (no flutter), it only holds the
  common base. The `google_sign_in` implementation moved to
  `tekartik_google_auth_flutter`.
* `GoogleAuthService` is now an interface, implemented by
  `GoogleAuthServiceBase`.
* Platform independent `GoogleAuthUser` replaces `GoogleSignInAccount` in the
  public api.
* `getClient()` returns a `googleapis_auth` `AuthClient?`, `getAuthHeaders()`
  is derived from it.
* Added `close()`, `debugGoogleAuthService` and the scope constants.

## 0.1.0

* Initial release
* GoogleAuthService for Google Sign-In integration
* PeopleApi helper for Google People API
* Stream-based authentication state management
