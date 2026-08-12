import 'dart:io';

import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Called with the consent [url] the user must open in a browser to grant
/// access.
///
/// Defaults to [tekartikGoogleAuthIoPromptUserConsent], override it through
/// `TekartikGoogleAuthOptionsIo.promptUserConsent` - typically from a flutter
/// app, to launch the url with `tekartik_app_url_launcher_flutter` instead of
/// the bare `dart:io` opener used here.
typedef TekartikGoogleAuthPromptUserConsent = Future<void> Function(String url);

/// Default consent prompt: writes [url] and launches it in the browser.
///
/// Replaces the `ioPromptUser` of `tekartik_io_auth_utils`, which only writes
/// it and leaves the user to copy/paste.
Future<void> tekartikGoogleAuthIoPromptUserConsent(String url) async {
  // Always write it too: the launch can fail, or open on another screen.
  stdout.writeln('Please go to the following URL and grant access:');
  stdout.writeln('  => $url');
  stdout.writeln('');
  await tekartikGoogleAuthIoLaunchUrl(url);
}

/// Launches [url] with the OS browser, does nothing on an unknown platform or
/// on failure (the url has been written anyway).
Future<void> tekartikGoogleAuthIoLaunchUrl(String url) async {
  String executable;
  List<String> arguments;
  if (Platform.isLinux) {
    executable = 'xdg-open';
    arguments = <String>[url];
  } else if (Platform.isMacOS) {
    executable = 'open';
    arguments = <String>[url];
  } else if (Platform.isWindows) {
    // The empty argument is the window title `start` expects first.
    executable = 'cmd';
    arguments = <String>['/c', 'start', '', url];
  } else {
    tekartikGoogleAuthLog(
      'no known url opener for ${Platform.operatingSystem}',
    );
    return;
  }
  try {
    tekartikGoogleAuthLog('launching $executable $arguments');
    await Process.start(executable, arguments, mode: ProcessStartMode.detached);
  } catch (e) {
    tekartikGoogleAuthLog('error launching $url: $e');
  }
}
