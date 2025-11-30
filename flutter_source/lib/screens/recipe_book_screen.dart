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

  void _showFullRecipe(BuildContext context, Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['title'] ?? 'Full Recipe'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recipe['description'] != null) ...[
                Text(recipe['description']!),
                const SizedBox(height: 16),
              ],
              
              const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._formatIngredients(recipe['ingredients']),
              
              const SizedBox(height: 16),
              const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._formatInstructions(recipe['instructions']),
              
              if (recipe['cookingTime'] != null || recipe['difficulty'] != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (recipe['cookingTime'] != null)
                      Chip(label: Text('⏱️ ${recipe['cookingTime']!}')),
                    if (recipe['difficulty'] != null)
                      Chip(label: Text('📊 ${recipe['difficulty']!}')),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Widget> _formatIngredients(dynamic ingredients) {
    if (ingredients == null) return [const Text('No ingredients listed')];
    if (ingredients is List) {
      return ingredients.map((ing) {
        if (ing is Map) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• ${ing['name'] ?? 'Unknown'}: ${ing['amount'] ?? 'Some'}'),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $ing'),
          );
        }
      }).toList();
    }
    return [const Text('No ingredients listed')];
  }

  List<Widget> _formatInstructions(dynamic instructions) {
    if (instructions == null) return [const Text('No instructions available')];
    if (instructions is List) {
      return instructions.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${entry.key + 1}. ${entry.value}'),
        );
      }).toList();
    }
    return [const Text('No instructions available')];
  }

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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _showFullRecipe(context, recipe),
                      tooltip: 'View Full Recipe',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        appState.removeRecipe(recipe['id']);
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (recipe['description'] != null) ...[
              const SizedBox(height: 8),
              Text(
                recipe['description']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showFullRecipe(context, recipe),
                child: const Text('View Full Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}