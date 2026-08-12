@TestOn('vm')
library;

import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:idb_shim/sdb/sdb.dart';
import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:test/test.dart';

import 'mock_private_key.dart';

TekartikGoogleAuthOptionsIo newOptions({
  KvStore? credentialsPersistence,
  String? credentialsKey,
  TekartikGoogleAuthPromptUserConsent? promptUserConsent,
}) => TekartikGoogleAuthOptionsIo(
  clientId: 'mock_client_id',
  clientSecret: 'mock_client_secret',
  projectId: 'mock_project',
  scopes: [tekartikGoogleAuthUserInfoProfileScope],
  credentialsPersistence: credentialsPersistence,
  credentialsKey: credentialsKey,
  promptUserConsent: promptUserConsent,
);

Future<void> mockPromptUserConsent(String url) async {}

TekartikGoogleAuthIo newAuth({
  KvStore? credentialsPersistence,
  String? credentialsKey,
  TekartikGoogleAuthPromptUserConsent? promptUserConsent,
}) =>
    tekartikGoogleAuthServiceIo.auth(
          newOptions(
            credentialsPersistence: credentialsPersistence,
            credentialsKey: credentialsKey,
            promptUserConsent: promptUserConsent,
          ),
        )
        as TekartikGoogleAuthIo;

/// Signed out auth, nothing is ever read from or written to the disk.
TekartikGoogleAuthIo newMemoryAuth() =>
    newAuth(credentialsPersistence: TekartikFirebasePersistenceMemory());

/// Not a real key: generated for the tests only.
final mockServiceAccountMap = <String, Object?>{
  'type': 'service_account',
  'project_id': 'mock_sa_project',
  'private_key_id': 'mock_key_id',
  'private_key': mockPrivateKey,
  'client_email': 'mock@mock_sa_project.iam.gserviceaccount.com',
  'client_id': 'mock_sa_client_id',
};

auth_io.AccessCredentials mockAccessCredentials({
  List<String>? scopes,
  String? refreshToken = 'mock_refresh_token',
}) => auth_io.AccessCredentials(
  auth_io.AccessToken(
    'Bearer',
    'mock_token',
    DateTime.utc(2030, 1, 2, 3, 4, 5),
  ),
  refreshToken,
  scopes ?? [tekartikGoogleAuthUserInfoProfileScope],
);

void main() {
  group('tekartikGoogleAuthServiceIo', () {
    test('global service', () {
      expect(tekartikGoogleAuthServiceIo, same(tekartikGoogleAuthServiceIo));
      expect(tekartikGoogleAuthServiceIo.name, 'io');
      expect(tekartikGoogleAuthServiceIo.supportsSignInSilently, isTrue);
    });

    test('auth() reuses the instance for equal options', () {
      var auth = newAuth();
      expect(newAuth(), same(auth));
      expect(newAuth(credentialsKey: 'other.yaml'), isNot(same(auth)));
      // Two persistences are the same only when they are the same object
      expect(newMemoryAuth(), isNot(same(newMemoryAuth())));
      expect(auth.service, tekartikGoogleAuthServiceIo);
    });
  });

  group('promptUserConsent', () {
    test('launches the url by default', () {
      // Unset in the options, resolved to the launching default on the auth.
      expect(newOptions().promptUserConsent, isNull);
      expect(
        newAuth().promptUserConsent,
        tekartikGoogleAuthIoPromptUserConsent,
      );
    });

    test('kept in the options', () {
      expect(
        newOptions(promptUserConsent: mockPromptUserConsent).promptUserConsent,
        mockPromptUserConsent,
      );
      expect(
        newAuth(promptUserConsent: mockPromptUserConsent).promptUserConsent,
        mockPromptUserConsent,
      );
    });

    test('a different prompt is a different instance', () {
      expect(
        newOptions(promptUserConsent: mockPromptUserConsent),
        isNot(newOptions()),
      );
      expect(
        newAuth(promptUserConsent: mockPromptUserConsent),
        isNot(same(newAuth())),
      );
    });
  });

  group('authViaServiceAccount', () {
    test('supported by the io service only', () {
      expect(tekartikGoogleAuthServiceIo.supportsServiceAccount, isTrue);
    });

    test('from a map and from a json string', () {
      for (var serviceAccount in <Object>[
        mockServiceAccountMap,
        jsonEncode(mockServiceAccountMap),
      ]) {
        var auth = tekartikGoogleAuthServiceIo.authViaServiceAccount(
          serviceAccount,
          scopes: [tekartikGoogleAuthUserInfoProfileScope],
        );
        expect(auth, isA<TekartikGoogleAuth>());
        expect(auth.clientId, 'mock_sa_client_id');
        expect(auth.options.projectId, 'mock_sa_project');
        expect(
          auth.options.email,
          'mock@mock_sa_project.iam.gserviceaccount.com',
        );
        expect(auth.scopes, [tekartikGoogleAuthUserInfoProfileScope]);
        // Nothing happened yet, signing in is what mints a token
        expect(auth.isSignedIn, isFalse);
      }
    });

    test('reuses the instance, impersonation included', () {
      var auth = tekartikGoogleAuthServiceIo.authViaServiceAccount(
        mockServiceAccountMap,
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      );
      expect(
        tekartikGoogleAuthServiceIo.authViaServiceAccount(
          mockServiceAccountMap,
          scopes: [tekartikGoogleAuthUserInfoProfileScope],
        ),
        same(auth),
      );
      // Different scopes or impersonated user, different instance
      expect(
        tekartikGoogleAuthServiceIo.authViaServiceAccount(
          mockServiceAccountMap,
          scopes: [tekartikGoogleAuthEmailScope],
        ),
        isNot(same(auth)),
      );
      var impersonated = tekartikGoogleAuthServiceIo.authViaServiceAccount(
        mockServiceAccountMap,
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
        impersonatedUser: 'someone@example.com',
      );
      expect(impersonated, isNot(same(auth)));
      expect(impersonated.options.impersonatedUser, 'someone@example.com');
      // The impersonated user is the one acted as
      expect(impersonated.serviceAccountUser.email, 'someone@example.com');
      expect(
        auth.serviceAccountUser.email,
        'mock@mock_sa_project.iam.gserviceaccount.com',
      );
    });

    test('the private key is not printed', () {
      var auth = tekartikGoogleAuthServiceIo.authViaServiceAccount(
        mockServiceAccountMap,
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      );
      expect(auth.options.toString(), isNot(contains('PRIVATE KEY')));
    });

    test('rejects a non service account json', () {
      expect(
        () => tekartikGoogleAuthServiceIo.authViaServiceAccount(
          {'type': 'authorized_user', 'client_id': 'x'},
          scopes: [tekartikGoogleAuthUserInfoProfileScope],
        ),
        throwsArgumentError,
      );
    });
  });

  group('TekartikGoogleAuthIo', () {
    test('is a TekartikGoogleAuth', () {
      var auth = newAuth();
      expect(auth, isA<TekartikGoogleAuth>());
      expect(auth.clientId, 'mock_client_id');
      expect(auth.scopes, ['https://www.googleapis.com/auth/userinfo.profile']);
      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('default persistence', () {
      var auth = newAuth();
      // A file in `.local`, relative to the current directory
      expect(
        auth.credentialsPersistence,
        isA<TekartikFirebasePersistenceFile>(),
      );
      expect(auth.credentialsKey, 'access_credentials.yaml');
      expect(auth.credentialsKey, tekartikGoogleAuthIoCredentialsKeyDefault);
    });

    test('sdb store', () async {
      var store = TekartikFirebasePersistenceSdb(
        sdbFactory: sdbFactoryMemory,
        dbName: 'google_auth_io_test',
      );
      var auth = newAuth(credentialsPersistence: store, credentialsKey: 'key');
      expect(auth.credentialsPersistence, same(store));
      expect(auth.credentialsKey, 'key');

      // The auth only ever needs the KvStore surface.
      var kvStore = auth.credentialsPersistence;
      await kvStore.setString('key', 'value');
      expect(await kvStore.getString('key'), 'value');
      await kvStore.remove('key');
      expect(await kvStore.getString('key'), isNull);
      await store.close();
    });

    test('in RAM client id map', () {
      var installed = newAuth().clientIdMap['installed'] as Map;
      expect(installed['client_id'], 'mock_client_id');
      expect(installed['client_secret'], 'mock_client_secret');
      expect(installed['project_id'], 'mock_project');
    });

    test('signInSilently does nothing without saved credentials', () async {
      var auth = newMemoryAuth();
      expect(await auth.hasSavedCredentials, isFalse);
      expect(await auth.signInSilently(), isNull);
      expect(auth.isSignedIn, isFalse);
      // No credentials to remove, no throw
      await auth.signOut();
      await auth.close();
    });

    test('signOut forgets the saved credentials', () async {
      var auth = newMemoryAuth();
      await auth.credentialsStore.save(mockAccessCredentials());
      expect(await auth.hasSavedCredentials, isTrue);
      await auth.signOut();
      expect(await auth.hasSavedCredentials, isFalse);
      await auth.close();
    });

    test('onCurrentUser.first is null without saved credentials', () async {
      var auth = newMemoryAuth();
      expect(await auth.hasSavedCredentials, isFalse);
      // Nothing to restore: resolves to null instead of blocking until the
      // next sign in.
      expect(
        await auth.onCurrentUser.first.timeout(const Duration(seconds: 5)),
        isNull,
      );
      expect(await auth.authReady, isTrue);
      await auth.close();
    });
  });

  group('TekartikGoogleAuthIoCredentialsStore', () {
    late KvStore persistence;
    late TekartikGoogleAuthIoCredentialsStore store;
    var scopes = [tekartikGoogleAuthUserInfoProfileScope];

    setUp(() {
      persistence = TekartikFirebasePersistenceMemory();
      store = TekartikGoogleAuthIoCredentialsStore(
        persistence: persistence,
        key: 'test_credentials',
      );
    });

    test('save/load round trip', () async {
      expect(await store.exists(), isFalse);
      expect(await store.load(scopes), isNull);

      await store.save(mockAccessCredentials(scopes: scopes));
      expect(await store.exists(), isTrue);

      var credentials = (await store.load(scopes))!;
      expect(credentials.accessToken.type, 'Bearer');
      expect(credentials.accessToken.data, 'mock_token');
      expect(credentials.accessToken.expiry, DateTime.utc(2030, 1, 2, 3, 4, 5));
      expect(credentials.accessToken.expiry.isUtc, isTrue);
      expect(credentials.refreshToken, 'mock_refresh_token');
      expect(credentials.scopes, scopes);

      await store.delete();
      expect(await store.exists(), isFalse);
      expect(await store.load(scopes), isNull);
    });

    test('saved in the tekartik_io_auth_utils json format', () async {
      await store.save(mockAccessCredentials(scopes: scopes));
      var map =
          jsonDecode((await persistence.getString('test_credentials'))!) as Map;
      expect(map['token_type'], 'Bearer');
      expect(map['token_data'], 'mock_token');
      expect(map['token_expiry'], '2030-01-02T03:04:05.000Z');
      expect(map['refresh_token'], 'mock_refresh_token');
      expect(map['scopes'], scopes);
    });

    test('other scopes are not restored', () async {
      await store.save(mockAccessCredentials(scopes: scopes));
      expect(await store.load([tekartikGoogleAuthEmailScope]), isNull);
      // The order is not meaningful, the set is
      await store.save(
        mockAccessCredentials(
          scopes: [tekartikGoogleAuthEmailScope, ...scopes],
        ),
      );
      expect(
        await store.load([...scopes, tekartikGoogleAuthEmailScope]),
        isNotNull,
      );
    });

    test('no refresh token, nothing to restore', () async {
      // An access token alone expires within the hour and cannot be renewed.
      await store.save(mockAccessCredentials(refreshToken: null));
      expect(await store.exists(), isTrue);
      expect(await store.load(scopes), isNull);
    });

    test('invalid content is ignored', () async {
      await persistence.setString('test_credentials', 'not json');
      expect(await store.load(scopes), isNull);
    });
  });

  group('TekartikGoogleAuthServiceAccountIo', () {
    test('listening never signs in', () async {
      var auth = tekartikGoogleAuthServiceIo.authViaServiceAccount(
        mockServiceAccountMap,
        scopes: [tekartikGoogleAuthEmailScope],
      );
      // A service account has no saved credentials, and restoring must not
      // mint a token over the network (the mock key would fail anyway).
      expect(
        await auth.onCurrentUser.first.timeout(const Duration(seconds: 5)),
        isNull,
      );
      expect(auth.isSignedIn, isFalse);
      await auth.close();
    });
  });
}
