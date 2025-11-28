import 'package:flutter/material.dart';
import 'screens/ingredients_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/recipe_book_screen.dart';

class FoodAssistantApp extends StatelessWidget {
  const FoodAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Assistant',
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;

  static const List<Widget> _screens = [
    IngredientsScreen(),
    RecipesScreen(),
    ChatScreen(),
    RecipeBookScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  IconData _getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  String _getThemeTooltip() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'System Theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MaterialApp(
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: isDarkMode ? Colors.tealAccent : Colors.white,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.kitchen),
              label: 'Ingredients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Assistant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Recipe Book',
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('Food Assistant'),
          actions: [
            IconButton(
              icon: Icon(_getThemeIcon()),
              onPressed: _toggleTheme,
              tooltip: _getThemeTooltip(),
            ),
          ],
        ),
      ),
    );
  }
}