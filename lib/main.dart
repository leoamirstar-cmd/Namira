import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_selection_screen.dart';
import 'package:namira/games/backgammon_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NamiraApp());
}

class NamiraApp extends StatefulWidget {
  const NamiraApp({super.key});

  @override
  State<NamiraApp> createState() => _NamiraAppState();
}

class _NamiraAppState extends State<NamiraApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'fa';
  String? _customBackgroundImage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('app_language') ?? 'fa';
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _customBackgroundImage = prefs.getString('custom_bg_image');
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() {
      _language = lang;
    });
  }

  Future<void> _setBackgroundImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_bg_image', path);
    setState(() {
      _customBackgroundImage = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namira Hub',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2481CC),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2481CC), brightness: Brightness.light),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2B5278),
        scaffoldBackgroundColor: const Color(0xFF0E1621),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5278), brightness: Brightness.dark),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: MainSelectionScreen(
        onToggleTheme: _toggleTheme,
        onChangeLanguage: _changeLanguage,
        onSetBackground: _setBackgroundImage,
        currentLanguage: _language,
        isDarkMode: _themeMode == ThemeMode.dark,
        customBackgroundImage: _customBackgroundImage,
      ),
    );
  }
}
