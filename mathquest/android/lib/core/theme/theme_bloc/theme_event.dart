// Freezed: run build_runner for full codegen
abstract class ThemeEvent {
  const ThemeEvent();
}

class ThemeLoadRequested extends ThemeEvent {
  const ThemeLoadRequested();
}

class ThemeToggled extends ThemeEvent {
  const ThemeToggled();
}
