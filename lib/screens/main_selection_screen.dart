import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_screen.dart';
import 'music_screen.dart';
import 'backgammon/backgammon_screen.dart'; // تنظیم مسیر پوشه backgammon

class MainSelectionScreen extends StatelessWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onChangeLanguage;
  final Function(String) onSetBackground;
  final String currentLanguage;
  final bool isDarkMode;
  final String? customBackgroundImage;

  const MainSelectionScreen({
    super.key,
    required this.onToggleTheme,
    required this.onChangeLanguage,
    required this.onSetBackground,
    required this.currentLanguage,
    required this.isDarkMode,
    this.customBackgroundImage,
  });

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onSetBackground(image.path);
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ListTile(
                leading: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.blueAccent),
                title: Text(currentLanguage == 'fa' ? 'تم تاریک / روشن' : 'Dark / Light Mode', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                trailing: Switch(
                  activeColor: Colors.pinkAccent,
                  value: isDarkMode,
                  onChanged: (val) {
                    onToggleTheme(val);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.pinkAccent),
                title: Text(currentLanguage == 'fa' ? 'زبان (فارسی / English)' : 'Language', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                trailing: DropdownButton<String>(
                  value: currentLanguage,
                  underline: const SizedBox(),
                  dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                    DropdownMenuItem(value: 'en', child: Text('EN')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      onChangeLanguage(val);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.wallpaper, color: Colors.purpleAccent),
                title: Text(currentLanguage == 'fa' ? 'انتخاب عکس پس‌زمینه' : 'Change Background', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // منوی انتخاب بازی‌ها
  void _showGamesMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentLanguage == 'fa' ? 'بازی‌های دورهمی' : 'Party Games',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.casino_rounded, color: Color(0xFF00E676), size: 32),
                title: Text(
                  currentLanguage == 'fa' ? 'تخته نرد (آفلاین)' : 'Backgammon (Offline)',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  currentLanguage == 'fa' ? 'بازی دو نفره' : 'Play backgammon',
                  style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackgammonScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFF4F4F6),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            image: customBackgroundImage != null && customBackgroundImage!.isNotEmpty
                ? DecorationImage(
                    image: FileImage(File(customBackgroundImage!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(isDarkMode ? 0.5 : 0.1), 
                      BlendMode.darken
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: currentLanguage == 'fa' ? 16 : null,
                  left: currentLanguage == 'fa' ? null : 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black26 : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.settings_outlined, color: isDarkMode ? Colors.white : Colors.black87),
                      onPressed: () => _showSettings(context),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0, bottom: 24.0, left: 24.0, right: 24.0),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.4),
                                  blurRadius: 25,
                                  spreadRadius: 8,
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: ClipOval(
                                child: Image.asset(
                                  "assets/images/namira_avatar.png",
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('N', style: TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.cyanAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              currentLanguage == 'fa' ? 'پلتفرم هوشمند نامیرا' : 'Namira Smart Platform',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentLanguage == 'fa' ? 'یک تجربه پرزرق‌وبرق و مدرن' : 'A vibrant & modern experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9, 
                        children: [
                          _buildGridCard(
                            context,
                            title: currentLanguage == 'fa' ? 'هوش مصنوعی' : 'Namira AI',
                            subtitle: currentLanguage == 'fa' ? 'چت ساده با دستیار' : 'Simple chat',
                            icon: Icons.chat_bubble_outline_rounded,
                            gradientColors: [const Color(0xFF2481CC), const Color(0xFF00C6FF)],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildGridCard(
                            context,
                            title: currentLanguage == 'fa' ? 'دانلود موزیک' : 'Music Club',
                            subtitle: currentLanguage == 'fa' ? 'جستجو و پخش آنلاین' : 'Stream & download',
                            icon: Icons.headphones_rounded,
                            gradientColors: [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MusicScreen(
                                    currentLanguage: currentLanguage,
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildGridCard(
                            context,
                            title: currentLanguage == 'fa' ? 'بازی‌های دورهمی' : 'Party Games',
                            subtitle: currentLanguage == 'fa' ? 'تخته‌نرد آفلاین' : 'Backgammon',
                            icon: Icons.casino_rounded,
                            gradientColors: [const Color(0xFF00E676), const Color(0xFF10B981)],
                            onTap: () => _showGamesMenu(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required List<Color> gradientColors, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const Spacer(),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            const SizedBox(height: 6),
            Text(
              subtitle, 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.3)
            ),
          ],
        ),
      ),
    );
  }
}
