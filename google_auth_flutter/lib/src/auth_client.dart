import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Authenticated client holder, signing in on demand.
class GoogleAuthClientService {
  /// Underlying google sign in.
  final GoogleSignIn googleSignIn;

  /// Cached authenticated client.
  ///
  /// The extension builds it with the access token of the moment, no refresh
  /// token and a fake far expiry: it is only reused while that token is still
  /// valid ([_clientMaxAge], the access tokens last an hour) and for the same
  /// account, then built again from a fresh token.
  AuthClient? _authenticatedClient;

  /// When [_authenticatedClient] was built.
  DateTime? _authenticatedClientTime;

  /// The account [_authenticatedClient] was built for.
  String? _authenticatedClientAccountId;

  /// Below the one hour lifetime of the access tokens.
  static const _clientMaxAge = Duration(minutes: 45);

  /// Authenticated client holder, signing in on demand.
  GoogleAuthClientService({required this.googleSignIn});

  /// Authenticated client, signing in (silently first) if needed.
  Future<AuthClient?> getClient() async {
    tekartikGoogleAuthLog('getClient called $_authenticatedClient');
    // Reuse the client while its token is valid, for the same account.
    var authenticatedClient = _authenticatedClient;
    var authenticatedClientTime = _authenticatedClientTime;
    if (authenticatedClient != null &&
        authenticatedClientTime != null &&
        DateTime.now().difference(authenticatedClientTime) < _clientMaxAge &&
        googleSignIn.currentUser?.id == _authenticatedClientAccountId) {
      return authenticatedClient;
    }
    clear();

    // Try to get the user silently (no UI popup)
    var currentUser = googleSignIn.currentUser;
    tekartikGoogleAuthLog('currentUser $currentUser');
    if (currentUser == null) {
      tekartikGoogleAuthLog('currentUser signInSilently');
      try {
        currentUser = await googleSignIn.signInSilently();
      } catch (error) {
        // Look for "DEVELOPER_ERROR" or "SIGN_IN_REQUIRED"
        tekartikGoogleAuthLog('error $error');
      }
    }

    /// No longer sign-in on web
    if (currentUser == null && !kIsWeb) {
      tekartikGoogleAuthLog('currentUser signIn');
      // If silent sign-in fails, we must trigger the interactive sign-in
      currentUser = await googleSignIn.signIn();
    }

    if (currentUser != null) {
      // #docregion RequestScopes
      if (!await googleSignIn.canAccessScopes(googleSignIn.scopes)) {
        await googleSignIn.requestScopes(googleSignIn.scopes);
      }

      tekartikGoogleAuthLog('currentUser: $currentUser');
      // Use the extension to create the authenticated client
      _authenticatedClient = await googleSignIn.authenticatedClient();
      _authenticatedClientTime = DateTime.now();
      _authenticatedClientAccountId = currentUser.id;
      tekartikGoogleAuthLog(
        'obtained authenticated client: $_authenticatedClient',
      );
      return _authenticatedClient;
    } else {
      tekartikGoogleAuthLog('no current user');
    }

    return null; // User cancelled or failed to sign in
  }

  /// Forget the cached client.
  void clear() {
    _authenticatedClient = null;
    _authenticatedClientTime = null;
    _authenticatedClientAccountId = null;
  }
}
