import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class RecipeBookScreen extends StatelessWidget {
  const RecipeBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Book'),
      ),
      body: appState.savedRecipes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved recipes yet!\nGenerate and save recipes to see them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: appState.savedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = appState.savedRecipes[index];
                return RecipeCard(recipe: recipe);
              },
            ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<FoodAppState>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe['title'] ?? 'Untitled Recipe',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    appState.removeRecipe(recipe['id']);
                  },
                ),
              ],
            ),
            if (recipe['description'] != null) ...[
              const SizedBox(height: 8),
              Text(recipe['description']!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (recipe['cookingTime'] != null)
                  Chip(
                    label: Text(recipe['cookingTime']!),
                    visualDensity: VisualDensity.compact,
                  ),
                if (recipe['difficulty'] != null)
                  Chip(
                    label: Text(recipe['difficulty']!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingredients: ${(recipe['ingredients'] as List?)?.length ?? 0}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}