import 'package:flutter/material.dart';

class ThemeState {
  const ThemeState({this.mode = ThemeMode.system});
  final ThemeMode mode;
  ThemeState copyWith({ThemeMode? mode}) =>
      ThemeState(mode: mode ?? this.mode);
}
