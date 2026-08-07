import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeState {
  final bool isDark;

  ThemeState(this.isDark);
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState(false)) {
    loadTheme(); // load on start
  }

  static const String _key = "isDarkTheme";

  // 🔄 Load saved theme
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;

    emit(ThemeState(isDark));
  }

  // 🔁 Toggle theme + save
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state.isDark;

    await prefs.setBool(_key, newValue);

    emit(ThemeState(newValue));
  }
}