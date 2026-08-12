import 'package:cv/cv_json.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:tekartik_google_auth/google_auth_impl.dart';
import 'package:tekartik_prefs/kv_store.dart';

/// Default key of the saved credentials in the persistence.
///
/// Historical name of the `tekartik_io_auth_utils` file (the content has
/// always been json), kept so an existing `.local/access_credentials.yaml` is
/// still read.
const tekartikGoogleAuthIoCredentialsKeyDefault = 'access_credentials.yaml';

/// Saved access/refresh token.
///
/// The field names are the ones of the `tekartik_io_auth_utils`
/// `access_credentials.yaml`, this reads and writes the same content.
class TekartikGoogleAuthCredentialsCv extends CvModelBase {
  /// Access token type, always `Bearer`.
  final tokenType = CvField<String>('token_type');

  /// Access token.
  final tokenData = CvField<String>('token_data');

  /// Access token expiry, in utc.
  final tokenExpiry = CvField.encodedDateTime('token_expiry');

  /// Refresh token, needed to refresh the access token once expired.
  final refreshToken = CvField<String>('refresh_token');

  /// Id token, when the openid scope was granted.
  final idToken = CvField<String>('id_token');

  /// Scopes the credentials were granted for.
  final scopes = CvListField<String>('scopes');

  @override
  CvFields get fields => [
    tokenType,
    tokenData,
    tokenExpiry,
    refreshToken,
    idToken,
    scopes,
  ];

  /// Saved access/refresh token.
  TekartikGoogleAuthCredentialsCv();

  /// Saved form of [credentials].
  factory TekartikGoogleAuthCredentialsCv.fromAccessCredentials(
    auth_io.AccessCredentials credentials,
  ) {
    var accessToken = credentials.accessToken;
    return TekartikGoogleAuthCredentialsCv()
      ..tokenType.v = accessToken.type
      ..tokenData.v = accessToken.data
      ..tokenExpiry.v = accessToken.expiry
      ..refreshToken.v = credentials.refreshToken
      ..idToken.v = credentials.idToken
      ..scopes.v = credentials.scopes;
  }

  /// The credentials for [scopes], `null` when they are unusable.
  ///
  /// Unusable means a missing token or, more likely, a missing refresh token:
  /// the access token alone expires within the hour and cannot be renewed, so
  /// there is nothing to restore and a new consent is needed.
  auth_io.AccessCredentials? toAccessCredentials(List<String> scopes) {
    var tokenData = this.tokenData.v;
    var tokenExpiry = this.tokenExpiry.v;
    var refreshToken = this.refreshToken.v;
    if (tokenData == null || tokenExpiry == null || refreshToken == null) {
      return null;
    }
    return auth_io.AccessCredentials(
      auth_io.AccessToken(
        tokenType.v ?? 'Bearer',
        tokenData,
        // The access token expiry must be in utc.
        tokenExpiry.toUtc(),
      ),
      refreshToken,
      scopes,
      idToken: idToken.v,
    );
  }
}

/// Where the access/refresh token of a `TekartikGoogleAuthIo` is cached.
///
/// This replaces the `.local/access_credentials.yaml` file handling of
/// `tekartik_io_auth_utils` with a [KvStore], so the credentials can be kept
/// anywhere (file, sdb, web local storage, memory, prefs).
class TekartikGoogleAuthIoCredentialsStore {
  /// Where the credentials are kept.
  final KvStore persistence;

  /// Key of the credentials in [persistence].
  final String key;

  /// Credentials store, on top of [persistence].
  TekartikGoogleAuthIoCredentialsStore({
    required this.persistence,
    required this.key,
  });

  /// Whether some credentials are saved, [load] can still return `null` if
  /// they are unusable.
  Future<bool> exists() async => await persistence.getString(key) != null;

  /// The saved credentials, `null` when there are none, when they cannot be
  /// read, or when they were granted for other [scopes].
  Future<auth_io.AccessCredentials?> load(List<String> scopes) async {
    var text = await persistence.getString(key);
    if (text == null) {
      return null;
    }
    try {
      var saved = text.cv<TekartikGoogleAuthCredentialsCv>(
        builder: (_) => TekartikGoogleAuthCredentialsCv(),
      );
      // Credentials granted for other scopes are useless, and no scope at all
      // (a file written by an older tool) says nothing about what was granted.
      var savedScopes = saved.scopes.v ?? const <String>[];
      if (!_sameScopes(savedScopes, scopes)) {
        tekartikGoogleAuthLog(
          'saved scopes $savedScopes do not match $scopes, signing in again',
        );
        return null;
      }
      var credentials = saved.toAccessCredentials(scopes);
      if (credentials == null) {
        tekartikGoogleAuthLog('incomplete saved credentials ($key)');
      }
      return credentials;
    } catch (e) {
      tekartikGoogleAuthLog('error reading the saved credentials ($key): $e');
      return null;
    }
  }

  /// Saves [credentials], replacing any previous ones.
  Future<void> save(auth_io.AccessCredentials credentials) async {
    await persistence.setString(
      key,
      TekartikGoogleAuthCredentialsCv.fromAccessCredentials(
        credentials,
      ).toJson(),
    );
  }

  /// Forgets the saved credentials, a no-op when there are none.
  Future<void> delete() async {
    await persistence.remove(key);
  }

  @override
  String toString() => '$key (${persistence.runtimeType})';
}

/// Scopes are a set, their order is not meaningful.
bool _sameScopes(List<String> scopes1, List<String> scopes2) {
  var set1 = scopes1.toSet();
  var set2 = scopes2.toSet();
  return set1.length == set2.length && set1.containsAll(set2);
}
