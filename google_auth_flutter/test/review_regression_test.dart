import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:tekartik_google_auth_flutter/google_auth_flutter.dart';

const _serverAuthCode = 'fake-server-auth-code';
const _accessToken = 'fake-access-token';

/// A signed in account with a server auth code (Android with a server
/// client id).
class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  @override
  bool get isMock => true;

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signInSilently() async => GoogleSignInUserData(
    email: 'user@example.com',
    id: 'user-id',
    serverAuthCode: _serverAuthCode,
  );

  @override
  Future<GoogleSignInTokenData> getTokens({
    required String email,
    bool? shouldRecoverAuth,
  }) async => GoogleSignInTokenData(accessToken: _accessToken);

  @override
  Future<bool> canAccessScopes(
    List<String> scopes, {
    String? accessToken,
  }) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the debug log prints no server auth code nor token', () async {
    GoogleSignInPlatform.instance = _FakeGoogleSignInPlatform();
    var logs = <String>[];
    debugTekartikGoogleAuthService = true;
    try {
      await runZoned(
        () async {
          var auth = tekartikGoogleAuthServiceFlutter.auth(
            TekartikGoogleAuthOptions(clientId: 'review_regression'),
          ) as TekartikGoogleAuthFlutter;
          await auth.signInSilently();
          var client = await auth.getClient();
          expect(client, isNotNull);
          await auth.close();
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) => logs.add(line),
        ),
      );
    } finally {
      debugTekartikGoogleAuthService = false;
    }
    expect(logs, isNotEmpty);
    for (var line in logs) {
      expect(line, isNot(contains(_serverAuthCode)));
      expect(line, isNot(contains(_accessToken)));
    }
  });
}
