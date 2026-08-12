/// Common (dart only) google authentication.
///
/// Implemented by `tekartik_google_auth_flutter` and
/// `tekartik_google_auth_io`.
library;

export 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

export 'src/google_auth_user.dart' show TekartikGoogleAuthUser;
export 'src/tekartik_google_auth.dart'
    show
        TekartikGoogleAuth,
        debugTekartikGoogleAuthService,
        tekartikGoogleAuthEmailScope,
        tekartikGoogleAuthProfileScope,
        tekartikGoogleAuthUserInfoProfileScope;
export 'src/tekartik_google_auth_service.dart'
    show TekartikGoogleAuthOptions, TekartikGoogleAuthService;
