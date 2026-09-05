import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_selection_screen.dart';

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

  // بارگذاری تنظیمات ذخیره شده از حافظه داخلی
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('app_language') ?? 'fa';
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _customBackgroundImage = prefs.getString('custom_bg_image');
    });
  }

  // تغییر و ذخیره تم
  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // تغییر و ذخیره زبان
  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() {
      _language = lang;
    });
  }

  // انتخاب عکس از گالری به عنوان پس‌زمینه و ذخیره آن
  Future<void> _pickBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_bg_image', image.path);
      setState(() {
        _customBackgroundImage = image.path;
      });
    }
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
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2B5278),
        scaffoldBackgroundColor: const Color(0xFF0E1621),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5278), brightness: Brightness.dark),
      ),
      home: MainSelectionScreen(
        onToggleTheme: _toggleTheme,
        onChangeLanguage: _changeLanguage,
        onPickBackground: _pickBackgroundImage,
        currentLanguage: _language,
        isDarkMode: _themeMode == ThemeMode.dark,
        customBackgroundImage: _customBackgroundImage,
      ),
    );
  }
}
