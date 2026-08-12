import 'package:flutter/material.dart';

/// Stub for the web-only renderButton method, since google_sign_in_web has to
/// be behind a conditional import.
Widget webRenderButton({WebGSIButtonConfiguration? configuration}) {
  throw StateError('webRenderButton. This should only be called on web');
}

/// Stub for the web-only GSI initialization.
Future<void> webInitializeGsi({required String clientId}) async {
  throw StateError('webInitializeGsi. This should only be called on web');
}

/// Stub for the web-only button configuration.
class WebGSIButtonConfiguration {
  /// Stub for the web-only button configuration.
  WebGSIButtonConfiguration() {
    throw StateError(
      'WebGSIButtonConfiguration. This should only be called on web',
    );
  }
}
