import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:test/test.dart';

/// Counts the silent sign in attempts, what a real backend turns into a
/// credentials read and a token refresh.
class _CountingGoogleAuth with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  _CountingGoogleAuth({required this.service, required this.options});

  var signInSilentlyCount = 0;

  @override
  Future<TekartikGoogleAuthUser?> signIn() async => null;

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async {
    signInSilentlyCount++;
    return null;
  }

  @override
  Future<void> signOut() async => currentUserAdd(null);

  @override
  Future<AuthClient?> getClient() async => null;
}

class _CountingGoogleAuthService with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'counting';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) => getInstance(
    options,
    () => _CountingGoogleAuth(service: this, options: options),
  );
}

void main() {
  group('review regression', () {
    test('authReady after close does not restore', () async {
      var auth =
          _CountingGoogleAuthService().auth(
                TekartikGoogleAuthOptions(clientId: 'id'),
              )
              as _CountingGoogleAuth;
      await auth.close();
      expect(await auth.authReady, isFalse);
      // A closed auth must not sign in (io: reads the saved credentials and
      // builds an auto refreshing client that nothing closes).
      expect(auth.signInSilentlyCount, 0);
    });
  });
}
