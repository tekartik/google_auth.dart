import 'package:dev_build/package.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  if (dartVersion >= Version(2, 12, 0, pre: '0')) {
    for (var dir in ['google_auth', 'google_auth_io', 'google_auth_test']) {
      await packageRunCi(join('..', dir));
    }
  }
}
