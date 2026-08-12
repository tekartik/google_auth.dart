// Console example, run with `dart run example/google_auth_io_example.dart`
import 'dart:io';

import 'package:tekartik_google_auth_io/google_auth_io.dart';

/// Replace with a "Desktop app" OAuth client of your project.
const clientId = 'my_client_id.apps.googleusercontent.com';
const clientSecret = 'my_client_secret';

Future<void> main() async {
  var auth = tekartikGoogleAuthServiceIo.auth(
    TekartikGoogleAuthOptionsIo(
      clientId: clientId,
      clientSecret: clientSecret,
      // Minimum scope needed to read the user info
      scopes: [tekartikGoogleAuthUserInfoProfileScope],
    ),
  );
  auth.onCurrentUser.listen((user) {
    stdout.writeln('current user: $user');
  });
  try {
    // Prints the consent url on stdout the first time
    await auth.signIn();

    // The client is ready for any googleapis api
    var client = await auth.getClient();
    stdout.writeln('client: $client');
  } finally {
    await auth.close();
  }
}
