/// Io (console/desktop, no flutter) google authentication.
library;

export 'package:tekartik_firebase_persistence/firebase_persistence.dart'
    show
        TekartikFirebasePersistenceMemory,
        TekartikFirebasePersistenceWebLocalStorage,
        TekartikFirebasePersistenceFile,
        TekartikFirebasePersistenceSdb;
export 'package:tekartik_google_auth/google_auth.dart';
export 'package:tekartik_prefs/kv_store.dart';

export 'src/tekartik_google_auth_io.dart'
    show
        TekartikGoogleAuthIo,
        TekartikGoogleAuthOptionsIo,
        TekartikGoogleAuthServiceIo,
        tekartikGoogleAuthServiceIo;
export 'src/tekartik_google_auth_io_credentials.dart'
    show
        TekartikGoogleAuthCredentialsCv,
        TekartikGoogleAuthIoCredentialsStore,
        tekartikGoogleAuthIoCredentialsKeyDefault;
export 'src/tekartik_google_auth_io_prompt.dart'
    show
        TekartikGoogleAuthPromptUserConsent,
        tekartikGoogleAuthIoLaunchUrl,
        tekartikGoogleAuthIoPromptUserConsent;
export 'src/tekartik_google_auth_service_account_io.dart'
    show
        TekartikGoogleAuthServiceAccountIo,
        TekartikGoogleAuthServiceAccountOptionsIo;
