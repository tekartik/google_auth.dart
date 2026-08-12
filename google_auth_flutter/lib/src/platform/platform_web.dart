import 'package:flutter/widgets.dart';
import 'package:google_identity_services_web/id.dart';
import 'package:google_identity_services_web/loader.dart' as gis;
import 'package:google_sign_in_web/web_only.dart';
import 'package:tekartik_google_auth/google_auth_impl.dart';

/// Web implementation of the GSI rendered button.
Widget webRenderButton({WebGSIButtonConfiguration? configuration}) {
  return renderButton(configuration: configuration?.toGSIButtonConfiguration());
}

/// Web only button configuration.
class WebGSIButtonConfiguration {
  /// Web only button configuration.
  WebGSIButtonConfiguration() {
    throw StateError(
      'WebGSIButtonConfiguration. This should only be called on web',
    );
  }

  /// The underlying GSI configuration.
  GSIButtonConfiguration toGSIButtonConfiguration() {
    return GSIButtonConfiguration();
  }
}

/// If you use the google_identity_services_web package directly for a custom "Sign In With Google" button:
Future<void> webInitializeGsi({required String clientId}) async {
  try {
    await gis.loadWebSdk();
  } catch (e) {
    tekartikGoogleAuthLog('error loading GSI SDK: $e');
    return;
  }
  id.initialize(
    IdConfiguration(
      client_id: clientId,
      callback: (credentialsResponse) {
        // Handle the credentials response
        tekartikGoogleAuthLog('GSI credentials response: $credentialsResponse');
      },
      use_fedcm_for_prompt: true, // This enables FedCM for One Tap
    ),
  );
}
