import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_google_auth/google_auth.dart';

export 'package:tekartik_app_dev_menu/dev_menu.dart';
export 'package:tekartik_google_auth/google_auth.dart';

/// Top doc context
class TekartikGoogleAuthMainMenuContext {
  /// The auth to play with.
  final TekartikGoogleAuth auth;

  /// Top doc context
  TekartikGoogleAuthMainMenuContext({required this.auth});
}

/// Google auth dev menu, `signIn` and `client`.
void tekartikGoogleAuthMainMenu({
  required TekartikGoogleAuthMainMenuContext context,
}) {
  var auth = context.auth;
  var service = auth.service;
  StreamSubscription? subscription;
  menu('signIn', () {
    item('service', () {
      write('service: $service');
      write('options: ${auth.options}');
      write('supportsSignInSilently: ${service.supportsSignInSilently}');
      write('supportsServiceAccount: ${service.supportsServiceAccount}');
    });
    item('current user', () async {
      write('current user: ${auth.currentUser}');
      write('isSignedIn: ${auth.isSignedIn}');
    });
    item('register on current user', () async {
      subscription?.cancel().unawait();
      subscription = auth.onCurrentUser.listen((user) {
        write('onUser: $user');
      });
    });
    item('cancel on current user', () {
      subscription?.cancel();
      subscription = null;
    });
    item('authReady', () async {
      write('authReady: ${await auth.authReady}');
      write('current user: ${auth.currentUser}');
    });
    item('signIn', () async {
      var user = await auth.signIn();
      write('user: $user');
    });
    item('signInSilently', () async {
      var user = await auth.signInSilently();
      write('user: $user');
    });
    item('signOut', () async {
      await auth.signOut();
    });
  });
  menu('client', () {
    item('getClient', () async {
      var client = await auth.getClient();
      write('client: $client');
      var credentials = client?.credentials;
      if (credentials != null) {
        write('accessToken expiry: ${credentials.accessToken.expiry}');
        write('scopes: ${credentials.scopes}');
        write('hasRefreshToken: ${credentials.refreshToken != null}');
      }
    });
    item('getAuthHeaders', () async {
      var headers = await auth.getAuthHeaders();
      write('headers: $headers');
    });
  });
}
