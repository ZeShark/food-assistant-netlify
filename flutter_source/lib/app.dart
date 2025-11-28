// ignore: unused_import
import 'package:flutter/material.dart';
import 'screens/ingredients_screen.dart';
import 'screens/recipes_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/recipe_book_screen.dart'; // Add this import

class FoodAssistantApp extends StatelessWidget {
  const FoodAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Assistant',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
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

  static final List<Widget> _screens = [
    const IngredientsScreen(),
    const RecipesScreen(),
    const ChatScreen(),
    const RecipeBookScreen(), // Add Recipe Book screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
          BottomNavigationBarItem( // Add Recipe Book item
            icon: Icon(Icons.menu_book),
            label: 'Recipe Book',
          ),
        ],
      ),
    );
  }
}