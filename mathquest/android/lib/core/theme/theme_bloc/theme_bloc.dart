import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

const _themeKey = 'theme_mode';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeLoadRequested>(_onLoad);
    on<ThemeToggled>(_onToggle);
  }

  Future<void> _onLoad(ThemeLoadRequested e, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey);
    final mode = index != null
        ? ThemeMode.values[index]
        : ThemeMode.system;
    emit(state.copyWith(mode: mode));
  }

  Future<void> _onToggle(ThemeToggled e, Emitter<ThemeState> emit) async {
    final next = switch (state.mode) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, next.index);
    emit(state.copyWith(mode: next));
  }
}
