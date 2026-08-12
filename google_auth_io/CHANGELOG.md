## 0.5.0

* Moved to its own public repository,
  [google_auth.dart](https://github.com/tekartik/google_auth.dart).
* **Breaking**: the package is renamed `tekartik_google_auth_io` (was
  `tekartik_google_auth_service_io`), and its library `google_auth_io.dart`
  (was `google_auth_service_io.dart`). The class names are unchanged.
* **Breaking**: `TekartikGoogleAuthOptionsIo.persistence` is renamed
  `credentialsPersistence` and is now a `KvStore` (`tekartik_prefs`), matching
  `GoogleAuthProviderRestIo` of `tekartik_firebase_auth_rest`. Every
  `tekartik_firebase_persistence` implementation is a `KvStore`, and so is a
  `PrefsLight`, so sembast/sdb/browser prefs can be used directly.

## 0.4.0

* No more `tekartik_io_auth_utils` dependency: the consent/credentials handling
  it provided is now done here, directly on `googleapis_auth`.
* **Breaking**: the credentials are cached through a
  `tekartik_firebase_persistence` `TekartikFirebasePersistence` instead of a
  file. `TekartikGoogleAuthOptionsIo.credentialsPath` is replaced by
  `persistence` (default: a file in `.local`) and `credentialsKey` (default:
  `access_credentials.yaml`), so they can also be kept in a database, in web
  local storage or in memory.
  The saved content is unchanged (the same json, read/written with `cv`), an
  existing `.local/access_credentials.yaml` is still read.
* **Breaking**: `TekartikGoogleAuthIo.hasSavedCredentials` is now a
  `Future<bool>`, the persistence is async.
* Saved credentials that were refused because the access was revoked are now
  dropped and a new consent is asked, instead of failing every sign in.
* Credentials saved without a refresh token are ignored, they could not be
  restored anyway.

## 0.3.0

* The consent url is now **launched** in the OS browser on top of being
  written, instead of the write-only `ioPromptUser` of
  `tekartik_io_auth_utils`. See `tekartikGoogleAuthIoPromptUserConsent`.
* New `TekartikGoogleAuthOptionsIo.promptUserConsent` to override it, e.g.
  with a `tekartik_app_url_launcher_flutter` based prompt from a flutter app.

## 0.2.0

* **Breaking**: `GoogleAuthServiceIo` is renamed `TekartikGoogleAuthIo` and is
  now created through `tekartikGoogleAuthServiceIo.auth(options)`.
* New `TekartikGoogleAuthServiceIo` and its global
  `tekartikGoogleAuthServiceIo`.
* New `TekartikGoogleAuthOptionsIo` carrying the io only `credentialsPath`.
* `close()`/`signOut()` tolerate a client the caller already closed.

## 0.1.0

* Initial release.
* `GoogleAuthServiceIo`, implementation of `GoogleAuthService` on top of
  `tekartik_io_auth_utils`, with the client id/secret kept in RAM and the
  credentials cached on the file system.
