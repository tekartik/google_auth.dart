## 0.3.0

* Moved to its own public repository,
  [google_auth.dart](https://github.com/tekartik/google_auth.dart).
* **Breaking**: the package is renamed `tekartik_google_auth_flutter` (was
  `tekartik_google_auth_service_flutter`), and its library
  `google_auth_flutter.dart` (was `google_auth_service_flutter.dart`). The
  class names are unchanged.

## 0.2.0

* **Breaking**: `GoogleAuthServiceFlutter` is renamed `TekartikGoogleAuthFlutter`
  and is now created through `tekartikGoogleAuthServiceFlutter.auth(options)`.
* New `TekartikGoogleAuthServiceFlutter` and its global
  `tekartikGoogleAuthServiceFlutter`.
* `GoogleSignInRenderButton`: the `authService` argument is renamed `auth`, and
  the non web button now actually signs in.

## 0.1.0

* Initial release, extracted from `tekartik_google_auth` 0.1.0.
* `GoogleAuthServiceFlutter` now implements the common `GoogleAuthService`
  interface (`GoogleAuthUser` instead of `GoogleSignInAccount`,
  `getClient()` instead of `client.getClient()`).
* The web only `google_identity_services_web` import is now behind the
  platform conditional import, so the package can be used off web.
