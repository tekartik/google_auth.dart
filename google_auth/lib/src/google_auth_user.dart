/// Platform independent signed in user information.
class TekartikGoogleAuthUser {
  /// Google account id (`sub`), null if unknown.
  final String? id;

  /// Email, null unless an email scope was requested.
  final String? email;

  /// Display name, null unless a profile scope was requested.
  final String? displayName;

  /// Avatar url, null unless a profile scope was requested.
  final String? photoUrl;

  /// Platform independent signed in user information.
  const TekartikGoogleAuthUser({
    this.id,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  /// Debug map.
  Map<String, Object?> toDebugMap() => <String, Object?>{
    if (id != null) 'id': id,
    if (email != null) 'email': email,
    if (displayName != null) 'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
  };

  @override
  String toString() => toDebugMap().toString();

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TekartikGoogleAuthUser &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;
}
