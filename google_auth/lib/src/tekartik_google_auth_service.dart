import 'package:meta/meta.dart';

import 'tekartik_google_auth.dart';

/// The options a [TekartikGoogleAuth] instance is created with.
///
/// Implementations can accept a subclass carrying extra settings (see
/// `TekartikGoogleAuthOptionsIo`), an unknown subclass is handled as this base
/// type.
class TekartikGoogleAuthOptions {
  /// OAuth client id.
  final String clientId;

  /// OAuth client secret.
  ///
  /// Required by the io/console flow, unused by the flutter implementation.
  final String? clientSecret;

  /// Google cloud project id, informative only.
  final String? projectId;

  /// Requested OAuth scopes.
  final List<String> scopes;

  /// The options a [TekartikGoogleAuth] instance is created with.
  TekartikGoogleAuthOptions({
    required this.clientId,
    this.clientSecret,
    this.projectId,
    List<String>? scopes,
  }) : scopes = List<String>.unmodifiable(scopes ?? const <String>[]);

  /// Debug map.
  @protected
  Map<String, Object?> toDebugMap() => <String, Object?>{
    'clientId': clientId,
    if (clientSecret != null) 'clientSecret': '***',
    if (projectId != null) 'projectId': projectId,
    'scopes': scopes,
  };

  @override
  String toString() => 'TekartikGoogleAuthOptions(${toDebugMap()})';

  @override
  int get hashCode => Object.hash(clientId, projectId, scopes.length);

  @override
  bool operator ==(Object other) =>
      other is TekartikGoogleAuthOptions &&
      other.runtimeType == runtimeType &&
      other.clientId == clientId &&
      other.clientSecret == clientSecret &&
      other.projectId == projectId &&
      _listEquals(other.scopes, scopes);
}

bool _listEquals(List<String> list1, List<String> list2) {
  if (list1.length != list2.length) {
    return false;
  }
  for (var i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }
  return true;
}

/// Represents a google auth service, i.e. the product level object that
/// creates and owns the [TekartikGoogleAuth] instances.
///
/// A concrete [TekartikGoogleAuthService] corresponds to one backend
/// (flutter/`google_sign_in`, io/console) and is available as a global object
/// (`tekartikGoogleAuthServiceFlutter`, `tekartikGoogleAuthServiceIo`); use
/// [auth] to obtain the [TekartikGoogleAuth] instance for given options.
abstract class TekartikGoogleAuthService {
  /// Implementation name, for debugging (`flutter`, `io`, ...).
  String get name;

  /// Whether this implementation can sign in without user interaction
  /// ([TekartikGoogleAuth.signInSilently]).
  bool get supportsSignInSilently;

  /// Whether this implementation supports [authViaServiceAccount].
  ///
  /// `true` only for `tekartikGoogleAuthServiceIo`: it needs the service
  /// account private key, which has no place in a shipped app.
  bool get supportsServiceAccount;

  /// Returns the [TekartikGoogleAuth] instance for [options], creating it on
  /// first access and reusing the same instance for equal [options].
  TekartikGoogleAuth auth(TekartikGoogleAuthOptions options);

  /// Returns a [TekartikGoogleAuth] authenticated as a service account,
  /// instead of as the user.
  ///
  /// [serviceAccount] is the downloaded service account json, either as a
  /// [Map] or as the encoded [String]:
  ///
  /// ```json
  /// {
  ///   "type": "service_account",
  ///   "project_id": "my-project",
  ///   "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  ///   "client_email": "me@my-project.iam.gserviceaccount.com",
  ///   "client_id": "1234567890"
  /// }
  /// ```
  ///
  /// There is no consent step: the private key signs a JWT that is exchanged
  /// for an access token, so signing in needs no browser and
  /// [TekartikGoogleAuth.signInSilently] is the normal path.
  /// [TekartikGoogleAuth.currentUser] is the service account itself, not a
  /// human - unless [impersonatedUser] is set (domain-wide delegation), in
  /// which case it is the impersonated user.
  ///
  /// Only supported when [supportsServiceAccount] is `true`, other
  /// implementations throw [UnsupportedError].
  TekartikGoogleAuth authViaServiceAccount(
    Object serviceAccount, {
    required List<String> scopes,
    String? impersonatedUser,
  });
}

/// Base mixin for [TekartikGoogleAuthService] implementations, handling the
/// per-options instance caching through [getInstance].
mixin TekartikGoogleAuthServiceMixin implements TekartikGoogleAuthService {
  final _instances = <TekartikGoogleAuthOptions, TekartikGoogleAuth>{};

  /// Returns the cached instance for [options], calling [create] on first
  /// access.
  @protected
  TekartikGoogleAuth getInstance(
    TekartikGoogleAuthOptions options,
    TekartikGoogleAuth Function() create,
  ) {
    return _instances.putIfAbsent(options, create);
  }

  /// Whether this implementation can sign in without user interaction.
  ///
  /// Defaults to `true`, override to opt out.
  @override
  bool get supportsSignInSilently => true;

  /// Whether this implementation supports [authViaServiceAccount].
  ///
  /// Defaults to `false`, override to opt in.
  @override
  bool get supportsServiceAccount => false;

  /// Default implementation, which is not supported by this mixin.
  ///
  /// Concrete classes that support it must override this member; as
  /// implemented here it always throws an [UnsupportedError].
  @override
  TekartikGoogleAuth authViaServiceAccount(
    Object serviceAccount, {
    required List<String> scopes,
    String? impersonatedUser,
  }) {
    throw UnsupportedError('$runtimeType.authViaServiceAccount not supported');
  }

  @override
  String toString() => 'TekartikGoogleAuthService($name)';
}
