@TestOn('vm')
library;

import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:tekartik_google_auth_test/google_auth_test.dart';
import 'package:test/test.dart';

/// The common tests on the io implementation, not signed in (nothing is
/// interactive, nothing is read from or written to the disk).
void main() {
  group('io', () {
    runGoogleAuthTests(
      service: tekartikGoogleAuthServiceIo,
      options: TekartikGoogleAuthOptionsIo(
        clientId: 'mock_client_id',
        clientSecret: 'mock_client_secret',
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
        // Nothing is read from or written to the disk
        credentialsPersistence: TekartikFirebasePersistenceMemory(),
      ),
    );
  });
}
