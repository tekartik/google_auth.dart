import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tekartikGoogleAuthServiceFlutter', () {
    test('global service', () {
      expect(
        tekartikGoogleAuthServiceFlutter,
        same(tekartikGoogleAuthServiceFlutter),
      );
      expect(tekartikGoogleAuthServiceFlutter.name, 'flutter');
    });

    test('auth() reuses the instance for equal options', () {
      var options = TekartikGoogleAuthOptions(clientId: '');
      var auth = tekartikGoogleAuthServiceFlutter.auth(options);
      expect(
        tekartikGoogleAuthServiceFlutter.auth(
          TekartikGoogleAuthOptions(clientId: ''),
        ),
        same(auth),
      );
      expect(auth.service, tekartikGoogleAuthServiceFlutter);
    });
  });

  group('TekartikGoogleAuthFlutter', () {
    test('is a TekartikGoogleAuth', () {
      var auth =
          tekartikGoogleAuthServiceFlutter.auth(
                TekartikGoogleAuthOptions(clientId: 'flutter_test_client'),
              )
              as TekartikGoogleAuthFlutter;
      expect(auth, isA<TekartikGoogleAuth>());
      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('scopes are forwarded to google sign in', () {
      var auth =
          tekartikGoogleAuthServiceFlutter.auth(
                TekartikGoogleAuthOptions(
                  clientId: 'flutter_test_scopes',
                  scopes: [
                    tekartikGoogleAuthEmailScope,
                    tekartikGoogleAuthProfileScope,
                  ],
                ),
              )
              as TekartikGoogleAuthFlutter;
      expect(auth.scopes, ['email', 'profile']);
      expect(auth.googleSignIn.scopes, ['email', 'profile']);
    });
  });
}
