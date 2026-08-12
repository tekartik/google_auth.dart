import 'dart:async';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/stream/subject.dart';

import 'google_auth_user.dart';
import 'tekartik_google_auth_service.dart';

/// Set to true to trace the auth service.
bool debugTekartikGoogleAuthService = false;

/// Internal debug log.
void tekartikGoogleAuthLog(Object? message) {
  if (debugTekartikGoogleAuthService) {
    // ignore: avoid_print
    print('[google_auth] $message');
  }
}

/// Common scope for the email.
const tekartikGoogleAuthEmailScope = 'email';

/// Common scope for the basic profile.
const tekartikGoogleAuthProfileScope = 'profile';

/// Minimum scope needed to read the user info.
const tekartikGoogleAuthUserInfoProfileScope =
    'https://www.googleapis.com/auth/userinfo.profile';

/// Google authentication, the entry point for all the auth operations of a
/// given [TekartikGoogleAuthOptions].
///
/// Obtain an instance through [TekartikGoogleAuthService.auth], on the
/// `tekartikGoogleAuthServiceFlutter` or `tekartikGoogleAuthServiceIo` global
/// service.
abstract class TekartikGoogleAuth {
  /// The service that created this instance.
  TekartikGoogleAuthService get service;

  /// The options this instance was created with.
  TekartikGoogleAuthOptions get options;

  /// OAuth client id, shortcut for `options.clientId`.
  String get clientId;

  /// Requested OAuth scopes, shortcut for `options.scopes`.
  List<String> get scopes;

  /// The currently signed in user, or `null` if no user is signed in or the
  /// current user has not been resolved yet.
  ///
  /// Use [onCurrentUser] to be notified when this value changes.
  TekartikGoogleAuthUser? get currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// A stream of the current user, emitting a new value each time the signed
  /// in user changes (including sign in and sign out).
  ///
  /// The first listener triggers a silent restore from the saved credentials
  /// (see [signInSilently]), so the first event is the restored user, or
  /// `null` when there is nothing to restore. Later listeners immediately
  /// receive the current value.
  ///
  /// This makes `await auth.onCurrentUser.first` the idiomatic way to get the
  /// signed in user before deciding whether to call [signIn]:
  ///
  /// ```dart
  /// var user = await auth.onCurrentUser.first;
  /// user ??= await auth.signIn();
  /// ```
  Stream<TekartikGoogleAuthUser?> get onCurrentUser;

  /// Resolves once the initial restore attempt is done.
  ///
  /// Awaiting it triggers the same restore as listening to [onCurrentUser],
  /// after which [currentUser]/[isSignedIn] are meaningful. Resolves to
  /// `false` if the auth was closed before the restore completed.
  Future<bool> get authReady;

  /// Starts a sign in flow, showing the platform UI/consent if needed.
  ///
  /// Returns `null` if the sign in failed or was cancelled. On success
  /// [currentUser] is updated and [onCurrentUser] notified.
  Future<TekartikGoogleAuthUser?> signIn();

  /// Signs in without any user interaction, using previously saved
  /// credentials.
  ///
  /// Returns `null` if there is nothing to restore.
  Future<TekartikGoogleAuthUser?> signInSilently();

  /// Signs out, forgetting any saved credentials.
  ///
  /// After this completes, [currentUser] is `null` and [onCurrentUser]
  /// emits `null`.
  Future<void> signOut();

  /// The authenticated client, `null` if not signed in.
  ///
  /// Ready to be given to a `googleapis` api object.
  Future<AuthClient?> getClient();

  /// Authentication headers for raw http calls, `null` if not signed in.
  Future<Map<String, String>?> getAuthHeaders();

  /// Releases the resources, after this [onCurrentUser] is done.
  Future<void> close();
}

/// Base mixin implementing [TekartikGoogleAuth] for concrete backends.
///
/// It provides the shared bookkeeping for the current user state
/// ([currentUser], [onCurrentUser], [currentUserAdd], [currentUserClose])
/// backed by a broadcast subject, and derives [getAuthHeaders] from
/// [getClient], so concrete implementations only provide the sign in
/// operations.
mixin TekartikGoogleAuthMixin implements TekartikGoogleAuth {
  /// Restores on first listen, so that `onCurrentUser.first` resolves to the
  /// saved user (or null) instead of blocking until the next sign in.
  late final _currentUserSubject = Subject<TekartikGoogleAuthUser?>(
    onListen: () => unawaited(_restoreCurrentUser()),
  );

  final _authReadyCompleter = Completer<bool>();

  /// The single restore attempt, `null` until the first one is triggered.
  Future<void>? _restoreFuture;

  /// Whether a first value was published, even a `null` one.
  ///
  /// Until then `currentUser` being null means "not resolved yet" rather than
  /// "signed out", and no event has reached the listeners.
  bool _currentUserResolved = false;

  @override
  late final Future<bool> authReady = () {
    unawaited(_restoreCurrentUser());
    return _authReadyCompleter.future;
  }();

  /// Restores the current user, once, then publishes the outcome.
  Future<void> _restoreCurrentUser() => _restoreFuture ??= () async {
    TekartikGoogleAuthUser? restored;
    try {
      restored = await restoreCurrentUser();
    } catch (e) {
      tekartikGoogleAuthLog('error restoring the current user: $e');
    }
    // Always publish, so a listener gets an event even when there was
    // nothing to restore. A no-op if the restore already published it.
    currentUserAdd(restored ?? currentUser);
    _authReadyComplete(true);
  }();

  /// Restores the signed in user from the saved credentials, `null` if there
  /// is nothing to restore.
  ///
  /// Called once, on the first [onCurrentUser] listen or [authReady] await.
  /// Defaults to [signInSilently], override to opt out (an implementation
  /// holding no saved credentials should return `null` rather than sign in,
  /// so that merely listening never triggers a network call).
  @protected
  Future<TekartikGoogleAuthUser?> restoreCurrentUser() async {
    if (!service.supportsSignInSilently) {
      return null;
    }
    return await signInSilently();
  }

  void _authReadyComplete(bool ready) {
    if (!_authReadyCompleter.isCompleted) {
      _authReadyCompleter.complete(ready);
    }
  }

  @override
  String get clientId => options.clientId;

  @override
  List<String> get scopes => options.scopes;

  @override
  TekartikGoogleAuthUser? get currentUser => _currentUserSubject.value;

  @override
  bool get isSignedIn => currentUser != null;

  @override
  Stream<TekartikGoogleAuthUser?> get onCurrentUser =>
      _currentUserSubject.stream;

  /// Publishes [user] as the new current user.
  ///
  /// This updates [currentUser] and notifies [onCurrentUser] listeners. Pass
  /// `null` to indicate that no user is currently signed in. Concrete
  /// implementations should call this whenever the signed in user changes.
  ///
  /// Publishing the same user twice is a no-op, no event is sent. The very
  /// first value is always published though, even a `null` one, so that
  /// listeners can tell "signed out" from "not resolved yet".
  @protected
  void currentUserAdd(TekartikGoogleAuthUser? user) {
    if (_currentUserResolved && user == currentUser) {
      return;
    }
    _currentUserResolved = true;
    tekartikGoogleAuthLog('user changed: $user');
    if (!_currentUserSubject.isClosed) {
      _currentUserSubject.add(user);
    }
  }

  /// Closes the internal current user stream.
  @protected
  Future<void> currentUserClose() async {
    await _currentUserSubject.close();
  }

  @override
  Future<Map<String, String>?> getAuthHeaders() async {
    var client = await getClient();
    if (client == null) {
      return null;
    }
    return <String, String>{
      'Authorization': 'Bearer ${client.credentials.accessToken.data}',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<void> close() async {
    // An in flight restore would never complete it, do not leave an awaiter
    // of `authReady` hanging.
    _authReadyComplete(false);
    await currentUserClose();
  }

  @override
  String toString() => '$runtimeType(${currentUser ?? 'signed out'})';
}
