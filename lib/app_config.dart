import 'package:flutter/material.dart';

class ChatTheme {
  static const Color primary = Color(0xFF0066FF);
  static const Color bg = Color(0xFFF3F5F8);
  static const Color bubbleMe = Color(0xFFDCEBFF);
  static const Color bubbleOther = Colors.white;
}

/// ¡Con slash final!
const String APP_INVITE_URL = 'https://valdepc.github.io/DELF-GLOBAL/';

/// Enlace canónico para invitaciones
String buildInviteUrl(String ref) =>
    '${APP_INVITE_URL}#/invite?ref=${Uri.encodeComponent(ref)}';
