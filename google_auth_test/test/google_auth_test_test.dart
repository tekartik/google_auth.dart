import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:tekartik_google_auth_test/google_auth_test.dart';
import 'package:test/test.dart';

/// Minimal in memory implementation, to run the common tests on.
class _MockGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  _MockGoogleAuth({required this.service, required this.options});

  static const user = TekartikGoogleAuthUser(
    id: 'mock_id',
    email: 'mock@example.com',
    displayName: 'Mock User',
  );

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    currentUserAdd(user);
    return currentUser;
  }

  /// Nothing saved, nothing to restore.
  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async => currentUser;

  @override
  Future<void> signOut() async => currentUserAdd(null);

  @override
  Future<AuthClient?> getClient() async => null;
}

class _MockGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'mock';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) => getInstance(
    options,
    () => _MockGoogleAuth(service: this, options: options),
  );
}

void main() {
  group('mock', () {
    runGoogleAuthTests(
      service: _MockGoogleAuthService(),
      options: TekartikGoogleAuthOptions(
        clientId: 'mock_client_id',
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      ),
    );
  });
}
