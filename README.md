# google_auth.dart

Google authentication for dart and flutter, a pub workspace.

Application code depends on an implementation but talks to the common
`TekartikGoogleAuth` api, so it can be swapped per platform.

| Package | Folder | Description |
| --- | --- | --- |
| `tekartik_google_auth` | [`google_auth/`](google_auth) | Common **dart only** base: the `TekartikGoogleAuthService` / `TekartikGoogleAuth` interfaces, `TekartikGoogleAuthUser`, and the shared implementation. |
| `tekartik_google_auth_flutter` | [`google_auth_flutter/`](google_auth_flutter) | Flutter implementation, using `google_sign_in` (with the web GSI render button). |
| `tekartik_google_auth_io` | [`google_auth_io/`](google_auth_io) | Console/desktop implementation (no flutter), using the `googleapis_auth` loopback consent url, with the credentials cached in a `KvStore`. |

## Setup

```yaml
dependencies:
  tekartik_google_auth_io:
    git:
      url: https://github.com/tekartik/google_auth.dart
      path: google_auth_io
    version: '>=0.4.0'
```

## Google OAuth credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Create an OAuth 2.0 client:
   * **Web application** for flutter web (add your origin, for example
     `http://localhost:8080`, to the authorized JavaScript origins)
   * **Desktop app** for the io/console flow (a web client rejects the random
     loopback port used by the console flow with `redirect_uri_mismatch`)

## Testing

```bash
# from the workspace root
(cd google_auth && dart test)
(cd google_auth_io && dart test)
(cd google_auth_flutter && flutter test)
```
