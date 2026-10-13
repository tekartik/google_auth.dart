import 'tekartik_google_auth.dart';

final _closedAuths = Expando<bool>('closed');

/// Marks [auth] as closed, so that the service cache does not hand it out
/// again (internal, not exported).
void tekartikGoogleAuthMarkClosed(TekartikGoogleAuth auth) {
  _closedAuths[auth] = true;
}

/// Whether [auth] was closed (only known for the mixin based implementations).
bool tekartikGoogleAuthIsClosed(TekartikGoogleAuth auth) =>
    _closedAuths[auth] ?? false;
