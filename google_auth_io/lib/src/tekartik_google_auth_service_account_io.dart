import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Options of a [TekartikGoogleAuthServiceAccountIo].
///
/// Built by `tekartikGoogleAuthServiceIo.authViaServiceAccount()`, the
/// [clientId]/[projectId] of the base options are the ones of the service
/// account.
class TekartikGoogleAuthServiceAccountOptionsIo
    extends TekartikGoogleAuthOptions {
  /// The parsed service account, holding the private key.
  final auth_io.ServiceAccountCredentials serviceAccountCredentials;

  /// Options of a [TekartikGoogleAuthServiceAccountIo].
  TekartikGoogleAuthServiceAccountOptionsIo({
    required this.serviceAccountCredentials,
    required super.scopes,
  }) : super(
         clientId: serviceAccountCredentials.clientId.identifier,
         projectId: serviceAccountCredentials.projectId,
       );

  /// Service account email.
  String get email => serviceAccountCredentials.email;

  /// Impersonated user (domain-wide delegation), null if none.
  String? get impersonatedUser => serviceAccountCredentials.impersonatedUser;

  @override
  Map<String, Object?> toDebugMap() => <String, Object?>{
    ...super.toDebugMap(),
    'email': email,
    if (impersonatedUser != null) 'impersonatedUser': impersonatedUser,
  };

  @override
  int get hashCode => Object.hash(super.hashCode, email, impersonatedUser);

  @override
  bool operator ==(Object other) =>
      other is TekartikGoogleAuthServiceAccountOptionsIo &&
      super == other &&
      other.email == email &&
      other.impersonatedUser == impersonatedUser;
}

/// Io implementation of [TekartikGoogleAuth] authenticating as a service
/// account.
///
/// Unlike [TekartikGoogleAuthIo] there is no consent step and nothing is
/// cached on disk: the private key signs a JWT that is exchanged for an access
/// token, which is then auto refreshed.
class TekartikGoogleAuthServiceAccountIo with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthServiceAccountOptionsIo options;

  auth_io.AutoRefreshingAuthClient? _client;

  /// Io implementation of [TekartikGoogleAuth] as a service account.
  TekartikGoogleAuthServiceAccountIo({
    required this.service,
    required this.options,
  });

  /// The service account, holding the private key.
  auth_io.ServiceAccountCredentials get serviceAccountCredentials =>
      options.serviceAccountCredentials;

  /// The user this auth acts as: the impersonated user if any, otherwise the
  /// service account itself.
  TekartikGoogleAuthUser get serviceAccountUser => TekartikGoogleAuthUser(
    id: options.clientId,
    email: options.impersonatedUser ?? options.email,
    displayName: options.email,
  );

  /// Nothing to restore: there are no saved credentials, the private key is
  /// the credential.
  ///
  /// [signInSilently] would mint a token over the network, which listening to
  /// [onCurrentUser] has no business doing. So this stays signed out until
  /// [signIn]/[signInSilently]/[getClient] is called explicitly.
  @override
  Future<TekartikGoogleAuthUser?> restoreCurrentUser() async => null;

  /// Signs in, no user interaction is ever needed.
  ///
  /// Same as [signInSilently].
  @override
  Future<TekartikGoogleAuthUser?> signIn() => signInSilently();

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() async {
    if (_client == null) {
      tekartikGoogleAuthLog('signing in as ${options.email}');
      _client = await auth_io.clientViaServiceAccount(
        serviceAccountCredentials,
        scopes,
      );
    }
    currentUserAdd(serviceAccountUser);
    return currentUser;
  }

  @override
  Future<AuthClient?> getClient() async {
    if (_client == null) {
      await signIn();
    }
    return _client;
  }

  @override
  Future<void> signOut() async {
    _closeClient();
    currentUserAdd(null);
  }

  @override
  Future<void> close() async {
    _closeClient();
    await super.close();
  }

  /// Closes the client, tolerating a caller that already closed it.
  void _closeClient() {
    var client = _client;
    _client = null;
    if (client != null) {
      try {
        client.close();
      } catch (e) {
        tekartikGoogleAuthLog('error closing client: $e');
      }
    }
  }
}
