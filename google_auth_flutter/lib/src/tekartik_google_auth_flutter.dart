import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tekartik_google_auth/google_auth_impl.dart';

import 'auth_client.dart';
import 'platform/platform.dart' as platform;

/// If you use the google_identity_services_web package directly for a custom
/// "Sign In With Google" button.
///
/// Web only, throws on any other platform.
Future<void> tekartikGoogleAuthInitializeGsi({required String clientId}) =>
    platform.webInitializeGsi(clientId: clientId);

/// Flutter implementation of [TekartikGoogleAuth], using google_sign_in.
class TekartikGoogleAuthFlutter with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  final GoogleSignIn _googleSignIn;
  late final GoogleAuthClientService _client;
  late final StreamSubscription<GoogleSignInAccount?> _subscription;

  /// Flutter implementation of [TekartikGoogleAuth], using google_sign_in.
  TekartikGoogleAuthFlutter({required this.service, required this.options})
    : _googleSignIn = GoogleSignIn(
        scopes: options.scopes,
        clientId: options.clientId,
      ) {
    _client = GoogleAuthClientService(googleSignIn: _googleSignIn);
    _subscription = _googleSignIn.onCurrentUserChanged.listen((account) {
      if (account == null) {
        _client.clear();
      }
      currentUserAdd(_toUser(account));
    });
  }

  /// Underlying google sign in, for advanced usage.
  GoogleSignIn get googleSignIn => _googleSignIn;

  TekartikGoogleAuthUser? _toUser(GoogleSignInAccount? account) {
    if (account == null) {
      return null;
    }
    return TekartikGoogleAuthUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }

  @override
  Future<TekartikGoogleAuthUser?> signIn() async {
    try {
      return _toUser(await _googleSignIn.signIn());
    } catch (error) {
      tekartikGoogleAuthLog('error signing in: $error');
      return null;
    }
  }

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async {
    try {
      return _toUser(await _googleSignIn.signInSilently());
    } catch (error) {
      tekartikGoogleAuthLog('error signing in silently: $error');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    _client.clear();
    await _googleSignIn.signOut();
    currentUserAdd(null);
  }

  @override
  Future<AuthClient?> getClient() => _client.getClient();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    _client.clear();
    await super.close();
  }

  /// Renders a web sign-in button.
  ///
  /// Throws an error if not on web platform.
  Widget webSignInButton() {
    return platform.webRenderButton();
  }
}

/// Flutter google auth service, using google_sign_in.
///
/// Use the [tekartikGoogleAuthServiceFlutter] global object.
class TekartikGoogleAuthServiceFlutter with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'flutter';

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) {
    return getInstance(
      options,
      () => TekartikGoogleAuthFlutter(service: this, options: options),
    );
  }
}

TekartikGoogleAuthServiceFlutter? _tekartikGoogleAuthServiceFlutter;

/// The flutter (google_sign_in) google auth service.
TekartikGoogleAuthServiceFlutter get tekartikGoogleAuthServiceFlutter =>
    _tekartikGoogleAuthServiceFlutter ??= TekartikGoogleAuthServiceFlutter();
