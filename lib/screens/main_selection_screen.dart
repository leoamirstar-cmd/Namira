import 'chat_screen_v2.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'music_screen.dart';

class MainSelectionScreen extends StatelessWidget {
  final Function(bool) onToggleTheme;
  final Function(String) onChangeLanguage;
  final String currentLanguage;
  final bool isDarkMode;

  const MainSelectionScreen({
    super.key,
    required this.onToggleTheme,
    required this.onChangeLanguage,
    required this.currentLanguage,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: currentLanguage == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF0E1621) : const Color(0xFFF4F4F6),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                ? [const Color(0xFF0E1621), const Color(0xFF1F1135), const Color(0xFF111E38)]
                : [const Color(0xFFE0F7FA), const Color(0xFFFCE4EC), const Color(0xFFF3E5F5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
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
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFancyMenuCard(
                    context,
                    title: currentLanguage == 'fa' ? 'هوش مصنوعی نامیرا' : 'Namira AI Assistant',
                    subtitle: currentLanguage == 'fa' ? 'چت و همراهی با دستیار هوشمند' : 'Chat with smart assistant',
                    icon: Icons.auto_awesome_rounded,
                    gradientColors: [const Color(0xFF2481CC), const Color(0xFF00C6FF)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            onToggleTheme: onToggleTheme,
                            onChangeLanguage: onChangeLanguage,
                            currentLanguage: currentLanguage,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildFancyMenuCard(
                    context,
                    title: currentLanguage == 'fa' ? 'کلاب دانلود موزیک' : 'Music Downloader Club',
                    subtitle: currentLanguage == 'fa' ? 'جستجو، پخش آنلاین و ذخیره موزیک' : 'Search, stream & download music',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFancyMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required List<Color> gradientColors, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
