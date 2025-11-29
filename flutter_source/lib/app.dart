import 'package:flutter/material.dart';
import 'screens/ingredients_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/recipe_book_screen.dart';

class FoodAssistantApp extends StatefulWidget {
  const FoodAssistantApp({super.key});

  @override
  State<FoodAssistantApp> createState() => _FoodAssistantAppState();
}

class _FoodAssistantAppState extends State<FoodAssistantApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Assistant',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: MainScreen(
        onThemeToggle: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// Light Theme
final ThemeData lightTheme = ThemeData.light().copyWith(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light,
    primary: Colors.green,
    secondary: Colors.deepPurple,
  ),
  scaffoldBackgroundColor: Colors.grey[50],
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 2,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.deepPurple,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey,
  ),
  // Fix dropdown text colors
  dropdownMenuTheme: DropdownMenuThemeData(
    textStyle: MaterialStateTextStyle.resolveWith(
      (Set<MaterialState> states) {
        return const TextStyle(color: Colors.black87);
      },
    ),
  ),
);

// Dark Theme
final ThemeData darkTheme = ThemeData.dark().copyWith(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.tealAccent,
    brightness: Brightness.dark,
    primary: Colors.tealAccent,
    secondary: Colors.greenAccent,
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.tealAccent,
    elevation: 4,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Colors.tealAccent,
    unselectedItemColor: Colors.grey,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1E1E1E),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF1E1E1E),
  ),
  // Fix dropdown text colors for dark mode
  dropdownMenuTheme: DropdownMenuThemeData(
    textStyle: MaterialStateTextStyle.resolveWith(
      (Set<MaterialState> states) {
        return const TextStyle(color: Colors.white);
      },
    ),
  ),
  // Fix input decoration text colors
  inputDecorationTheme: const InputDecorationTheme(
    labelStyle: TextStyle(color: Colors.grey),
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(color: Colors.tealAccent),
  ),
);

class MainScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Assistant'),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.green,
        foregroundColor: widget.isDarkMode ? Colors.tealAccent : Colors.white,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.deepPurple,
        selectedItemColor: widget.isDarkMode ? Colors.tealAccent : Colors.white,
        unselectedItemColor: widget.isDarkMode ? Colors.grey : Colors.grey[300],
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
    );
  }
}