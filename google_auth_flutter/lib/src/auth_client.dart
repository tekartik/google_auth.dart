import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Authenticated client holder, signing in on demand.
class GoogleAuthClientService {
  /// Underlying google sign in.
  final GoogleSignIn googleSignIn;

  /// Cached authenticated client.
  AuthClient? _authenticatedClient;

  /// Authenticated client holder, signing in on demand.
  GoogleAuthClientService({required this.googleSignIn});

  /// Authenticated client, signing in (silently first) if needed.
  Future<AuthClient?> getClient() async {
    tekartikGoogleAuthLog('getClient called $_authenticatedClient');
    // If we already have a client, return it immediately (Efficiency!)
    if (_authenticatedClient != null) {
      return _authenticatedClient;
    }

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
  }
}
