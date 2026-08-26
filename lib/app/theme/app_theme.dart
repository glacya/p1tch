import 'package:flutter/material.dart';

abstract class AppTheme {
  AppTheme._();

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  );
}
