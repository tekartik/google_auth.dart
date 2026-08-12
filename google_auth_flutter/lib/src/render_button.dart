import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tekartik_google_auth_flutter.dart';

/// Google sign in button.
///
/// Uses the GSI rendered button on web, a plain [ElevatedButton] elsewhere.
class TekartikGoogleSignInRenderButton extends StatefulWidget {
  /// The auth object to sign in with.
  final TekartikGoogleAuthFlutter auth;

  /// Google sign in button.
  const TekartikGoogleSignInRenderButton({super.key, required this.auth});

  @override
  State<TekartikGoogleSignInRenderButton> createState() =>
      _TekartikGoogleSignInRenderButtonState();
}

class _TekartikGoogleSignInRenderButtonState
    extends State<TekartikGoogleSignInRenderButton> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return widget.auth.webSignInButton();
    }
    return ElevatedButton.icon(
      onPressed: () async {
        await widget.auth.signIn();
      },
      icon: const Icon(Icons.login),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
