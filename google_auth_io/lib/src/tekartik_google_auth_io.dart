import 'package:googleapis/oauth2/v2.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:tekartik_firebase_persistence/firebase_persistence.dart'
    show
        TekartikFirebasePersistenceFile,
        TekartikFirebasePersistenceMemory,
        TekartikFirebasePersistenceSdb;
import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:tekartik_prefs/kv_store.dart';

import 'tekartik_google_auth_io_credentials.dart';
import 'tekartik_google_auth_io_prompt.dart';
import 'tekartik_google_auth_service_account_io.dart';

/// Io ([TekartikGoogleAuthServiceIo]) specific options.
class TekartikGoogleAuthOptionsIo extends TekartikGoogleAuthOptions {
  /// Where the access/refresh token is cached.
  ///
  /// Defaults to a [TekartikFirebasePersistenceFile] in `.local`, relative to
  /// the current directory. Any other [KvStore] works, in memory
  /// ([TekartikFirebasePersistenceMemory]) for a sign in that must not
  /// survive the process, sdb ([TekartikFirebasePersistenceSdb]) for an app
  /// that already has a database, or a `PrefsLight` based one.
  final KvStore? credentialsPersistence;

  /// Key of the cached access/refresh token in [credentialsPersistence].
  ///
  /// Defaults to [tekartikGoogleAuthIoCredentialsKeyDefault]. Give each
  /// account its own key to keep several sign ins side by side.
  final String? credentialsKey;

  /// How the consent url is given to the user.
  ///
  /// Defaults to [tekartikGoogleAuthIoPromptUserConsent], which writes it and
  /// launches it with the OS browser. A flutter app should override it with a
  /// `tekartik_app_url_launcher_flutter` based one.
  final TekartikGoogleAuthPromptUserConsent? promptUserConsent;

  /// Io specific options.
  TekartikGoogleAuthOptionsIo({
    required super.clientId,
    required super.clientSecret,
    super.projectId,
    super.scopes,
    this.credentialsPersistence,
    this.credentialsKey,
    this.promptUserConsent,
  });

  @override
  Map<String, Object?> toDebugMap() => <String, Object?>{
    ...super.toDebugMap(),
    if (credentialsPersistence != null)
      'credentialsPersistence': '${credentialsPersistence.runtimeType}',
    if (credentialsKey != null) 'credentialsKey': credentialsKey,
  };

  @override
  int get hashCode => Object.hash(
    super.hashCode,
    credentialsPersistence,
    credentialsKey,
    promptUserConsent,
  );

  @override
  bool operator ==(Object other) =>
      other is TekartikGoogleAuthOptionsIo &&
      super == other &&
      other.credentialsPersistence == credentialsPersistence &&
      other.credentialsKey == credentialsKey &&
      other.promptUserConsent == promptUserConsent;
}

/// Io (console/desktop) implementation of [TekartikGoogleAuth].
///
/// The client id/secret are kept in RAM (nothing is read from a
/// `client_secret.json` file), the access/refresh token is cached in
/// [credentialsPersistence] under [credentialsKey].
///
/// Signing in opens a loopback http server and hands the consent url to
/// [promptUserConsent], which by default writes it and launches the OS
/// browser. This requires a **Desktop app** OAuth client, a *Web application*
/// client would reject the random loopback port with `redirect_uri_mismatch`.
class TekartikGoogleAuthIo with TekartikGoogleAuthMixin {
  @override
  final TekartikGoogleAuthService service;

  @override
  final TekartikGoogleAuthOptions options;

  /// The signed in client, closing it closes the http client it was built on.
  auth_io.AutoRefreshingAuthClient? _client;

  /// Io (console/desktop) implementation of [TekartikGoogleAuth].
  TekartikGoogleAuthIo({required this.service, required this.options});

  /// OAuth client secret, required for the console flow.
  String get clientSecret {
    var clientSecret = options.clientSecret;
    if (clientSecret == null) {
      throw StateError('clientSecret is required for $runtimeType');
    }
    return clientSecret;
  }

  TekartikGoogleAuthOptionsIo? get _optionsIo =>
      options is TekartikGoogleAuthOptionsIo
      ? options as TekartikGoogleAuthOptionsIo
      : null;

  /// Where the access/refresh token is cached.
  ///
  /// Defaults to a file in `.local`, relative to the current directory.
  late final KvStore credentialsPersistence =
      _optionsIo?.credentialsPersistence ?? TekartikFirebasePersistenceFile();

  /// Key of the access/refresh token in [credentialsPersistence].
  late final String credentialsKey =
      _optionsIo?.credentialsKey ?? tekartikGoogleAuthIoCredentialsKeyDefault;

  /// Where the access/refresh token is cached, read and written by the sign in.
  late final TekartikGoogleAuthIoCredentialsStore credentialsStore =
      TekartikGoogleAuthIoCredentialsStore(
        persistence: credentialsPersistence,
        key: credentialsKey,
      );

  /// How the consent url is given to the user.
  ///
  /// Defaults to [tekartikGoogleAuthIoPromptUserConsent].
  TekartikGoogleAuthPromptUserConsent get promptUserConsent =>
      _optionsIo?.promptUserConsent ?? tekartikGoogleAuthIoPromptUserConsent;

  /// OAuth client id/secret, the identity of the app itself.
  auth_io.ClientId get authClientId => auth_io.ClientId(clientId, clientSecret);

  /// In memory (RAM) client id map, in the google `client_secret.json`
  /// `installed` (desktop app) format.
  ///
  /// Nothing here reads it, it is the equivalent of the file that would
  /// otherwise be downloaded from the cloud console, for a tool that wants it.
  Map<String, Object?> get clientIdMap => <String, Object?>{
    'installed': <String, Object?>{
      'client_id': clientId,
      if (options.projectId != null) 'project_id': options.projectId,
      'auth_uri': 'https://accounts.google.com/o/oauth2/auth',
      'token_uri': 'https://oauth2.googleapis.com/token',
      'client_secret': clientSecret,
      'redirect_uris': <Object?>['http://localhost'],
    },
  };

  /// Whether some credentials are cached, [signInSilently] only works then.
  Future<bool> get hasSavedCredentials => credentialsStore.exists();

  @override
  Future<TekartikGoogleAuthUser?> signIn() => _signIn(silent: false);

  @override
  Future<TekartikGoogleAuthUser?> signInSilently() => _signIn(silent: true);

  Future<TekartikGoogleAuthUser?> _signIn({required bool silent}) async {
    if (_client != null) {
      return currentUser;
    }
    try {
      var credentials = await credentialsStore.load(scopes);
      if (credentials == null) {
        if (silent) {
          tekartikGoogleAuthLog('no saved credentials ($credentialsStore)');
          return null;
        }
      } else {
        try {
          return await _signInWithCredentials(credentials);
        } catch (e) {
          if (silent || !_isInvalidGrant(e)) {
            rethrow;
          }
          // Revoked or expired refresh token, only a new consent can help.
          tekartikGoogleAuthLog('saved credentials refused ($e), signing in');
          await credentialsStore.delete();
        }
      }
      var newCredentials = await _obtainCredentialsViaUserConsent();
      await credentialsStore.save(newCredentials);
      return await _signInWithCredentials(newCredentials);
    } catch (e) {
      tekartikGoogleAuthLog('error signing in: $e');
      if (!silent) {
        rethrow;
      }
      return null;
    }
  }

  /// Builds the auto refreshing client for [credentials] and reads the user
  /// info, keeping the client only if that succeeded.
  Future<TekartikGoogleAuthUser?> _signInWithCredentials(
    auth_io.AccessCredentials credentials,
  ) async {
    // Closed with the auth client (`closeUnderlyingClient` defaults to true).
    var client = auth_io.autoRefreshingClient(
      authClientId,
      credentials,
      http.Client(),
    );
    try {
      var user = await _readUserInfo(client);
      _client = client;
      currentUserAdd(user);
      return currentUser;
    } catch (e) {
      client.close();
      rethrow;
    }
  }

  /// Runs the consent flow: a loopback http server waits for the user to grant
  /// access to the url handed to [promptUserConsent].
  Future<auth_io.AccessCredentials> _obtainCredentialsViaUserConsent() async {
    var client = http.Client();
    try {
      return await auth_io.obtainAccessCredentialsViaUserConsent(
        authClientId,
        scopes,
        client,
        promptUserConsent,
      );
    } finally {
      client.close();
    }
  }

  /// Whether [error] means the saved credentials are dead (access revoked or
  /// refresh token expired), as opposed to a transient failure.
  bool _isInvalidGrant(Object error) {
    if (error is auth_io.ServerRequestFailedException) {
      var content = error.responseContent;
      return content is Map && content['error'] == 'invalid_grant';
    }
    return false;
  }

  Future<TekartikGoogleAuthUser> _readUserInfo(AuthClient client) async {
    var userInfo = await Oauth2Api(client).userinfo.get();
    return TekartikGoogleAuthUser(
      id: userInfo.id,
      email: userInfo.email,
      displayName: userInfo.name,
      photoUrl: userInfo.picture,
    );
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
    tekartikGoogleAuthLog('deleting the credentials ($credentialsStore)');
    await credentialsStore.delete();
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

/// Io (console/desktop, no flutter) google auth service.
///
/// Use the [tekartikGoogleAuthServiceIo] global object.
class TekartikGoogleAuthServiceIo with TekartikGoogleAuthServiceMixin {
  @override
  String get name => 'io';

  @override
  bool get supportsServiceAccount => true;

  @override
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options) {
    return getInstance(
      options,
      () => TekartikGoogleAuthIo(service: this, options: options),
    );
  }

  @override
  TekartikGoogleAuthServiceAccountIo authViaServiceAccount(
    Object serviceAccount, {
    required List<String> scopes,
    String? impersonatedUser,
  }) {
    var options = TekartikGoogleAuthServiceAccountOptionsIo(
      serviceAccountCredentials: auth_io.ServiceAccountCredentials.fromJson(
        serviceAccount,
        impersonatedUser: impersonatedUser,
      ),
      scopes: scopes,
    );
    return getInstance(
          options,
          () => TekartikGoogleAuthServiceAccountIo(
            service: this,
            options: options,
          ),
        )
        as TekartikGoogleAuthServiceAccountIo;
  }
}

TekartikGoogleAuthServiceIo? _tekartikGoogleAuthServiceIo;

/// The io (console/desktop, no flutter) google auth service.
TekartikGoogleAuthServiceIo get tekartikGoogleAuthServiceIo =>
    _tekartikGoogleAuthServiceIo ??= TekartikGoogleAuthServiceIo();
