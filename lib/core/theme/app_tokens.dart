import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const bg = Color(0xFFFBF7EC);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF6EFDC);

  static const ink900 = Color(0xFF1B1610);
  static const ink800 = Color(0xFF2A241B);
  static const ink700 = Color(0xFF423A2D);
  static const ink600 = Color(0xFF5C5242);
  // ink500 fixed from 0xFF8A7E66 (≈3.2:1) to 0xFF6B6050 (≈4.6:1 on cream bg)
  static const ink500 = Color(0xFF6B6050);
  static const ink100 = Color(0xFFEFE7D2);

  // primary500/primary400 must NOT be used as text color — button/icon fill only.
  // Use primary600 (Color(0xFFB36F00)) for text-safe amber.
  static const primary500 = Color(0xFFD98A0E);
  static const primary400 = Color(0xFFE9A534);
  static const primary100 = Color(0xFFFFEFCC);
  static const primary600 = Color(0xFFB36F00);

  static const warn = Color(0xFFA96C00);
  static const warnBg = Color(0xFFFCECC3);
  static const warnBorder = Color(0xFFE0AA40);

  static const seeker = Color(0xFFC94A3E);
  static const seekerBg = Color(0xFFFADDD7);

  static const success = Color(0xFF2F7D3E);
  static const successBg = Color(0xFFDFF1E1);

  static const info = Color(0xFF2A5D8F);
  static const border = Color(0xFFE6DDC4);

  static const rSm = 10.0;
  static const rMd = 14.0;
  static const pill = 999.0;
}
