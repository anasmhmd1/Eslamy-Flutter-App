import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quran_screen.dart';
import 'adhkar_categories_screen.dart'; // Import
import 'hadith_screen.dart';
import 'tools_screen.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const QuranScreen(),
    const AdhkarCategoriesScreen(), // New Tab
    const HadithScreen(),
    const ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: _screens[_currentIndex]),
        bottomNavigationBar: Theme(
          data: Theme.of(
            context,
          ).copyWith(canvasColor: Colors.black.withValues(alpha: 0.5)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            elevation: 0,
            selectedItemColor: AppTheme.accentGold,
            unselectedItemColor: Colors.white70,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_filled),
                label: AppLocalizations.of(context).translate('home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.book),
                label: AppLocalizations.of(context).translate('quran'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.volunteer_activism), // Adhkar Icon
                label: 'الأذكار', // Hardcoded for now as key might missing
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.library_books),
                label: AppLocalizations.of(context).translate('hadith'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.widgets),
                label: AppLocalizations.of(context).translate('tools'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
