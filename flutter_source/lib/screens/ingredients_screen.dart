import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load ingredients when screen starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodAppState>().loadIngredients();
    });
  }

  void _addIngredient() {
    final name = _ingredientController.text.trim();
    if (name.isNotEmpty) {
      context.read<FoodAppState>().addIngredient(name);
      _ingredientController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _importIngredients() {
    final text = _importController.text.trim();
    if (text.isNotEmpty) {
      final ingredients = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      context.read<FoodAppState>().importIngredients(ingredients);
      _importController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ingredients'),
        actions: [
          if (appState.ingredients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                // Clear all ingredients (you can implement this)
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Add ingredient section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _ingredientController,
                  decoration: InputDecoration(
                    labelText: 'Add Ingredient',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addIngredient,
                    ),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _importController,
                  decoration: InputDecoration(
                    labelText: 'Import Multiple (comma separated)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.file_upload),
                      onPressed: _importIngredients,
                    ),
                  ),
                  onSubmitted: (_) => _importIngredients(),
                ),
              ],
            ),
          ),
          
          // Ingredients list
          Expanded(
            child: appState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : appState.ingredients.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.kitchen, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No ingredients yet!\nAdd some to get recipe suggestions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: appState.ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = appState.ingredients[index];
                          return ListTile(
                            leading: const Icon(Icons.kitchen),
                            title: Text(ingredient['name']),
                            subtitle: Text(ingredient['category'] ?? 'uncategorized'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<FoodAppState>().deleteIngredient(ingredient['id'].toString());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}