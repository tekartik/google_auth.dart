// Console menu example, run with:
//   dart run example/google_auth_io_menu_example.dart
//
// The client id/secret are asked once in the `kv` menu (they are saved as
// vars), they must come from a "Desktop app" OAuth client.
import 'package:tekartik_google_auth_io/google_auth_io.dart';
import 'package:tekartik_google_auth_test/menu/google_auth_client_menu.dart';

var clientIdKv = 'google_auth_io_menu_example.client_id'.kvFromVar();
var clientSecretKv = 'google_auth_io_menu_example.client_secret'.kvFromVar();

Future<void> main(List<String> args) async {
  await mainMenu(args, () {
    var auth = tekartikGoogleAuthServiceIo.auth(
      TekartikGoogleAuthOptionsIo(
        clientId: clientIdKv.value ?? 'missing_client_id',
        clientSecret: clientSecretKv.value,
        // Minimum scope needed to read the user info
        scopes: [tekartikGoogleAuthUserInfoProfileScope],
      ),
    );
    tekartikGoogleAuthMainMenu(
      context: TekartikGoogleAuthMainMenuContext(auth: auth),
    );
    keyValuesMenu('kv', [clientIdKv, clientSecretKv]);
  });
}
