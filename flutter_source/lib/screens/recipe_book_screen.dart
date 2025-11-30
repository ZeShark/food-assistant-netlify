import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:js' as js;
import '../app_state.dart';

class RecipeBookScreen extends StatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  State<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen> {
  bool _showInstallButton = false;

  @override
  void initState() {
    super.initState();
    _checkPwaInstallable();
  }

  void _checkPwaInstallable() {
    // Check if PWA install is available using the global function
    try {
      final isAvailable = js.context.callMethod('getPwaInstallStatus');
      setState(() {
        _showInstallButton = isAvailable ?? false;
      });
    } catch (e) {
      print('PWA check error: $e');
      // Fallback: check if deferredPrompt exists
      try {
        final hasPrompt = js.context.hasProperty('deferredPrompt');
        setState(() {
          _showInstallButton = hasPrompt;
        });
      } catch (e) {
        print('Fallback PWA check also failed: $e');
      }
    }
  }

  Future<void> _installPwa() async {
    try {
      js.context.callMethod('installPwa');
      // Hide button after installation attempt
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showInstallButton = false);
        }
      });
    } catch (e) {
      _showInstallInstructions();
    }
  }

  void _showInstallInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Install Food Assistant'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To install this app:'),
            SizedBox(height: 12),
            Text('• Android/Chrome: Tap ⋮ → "Add to Home screen"'),
            Text('• iOS/Safari: Tap ⎕ → "Add to Home Screen"'),
            Text('• Desktop: Look for install icon in address bar'),
            SizedBox(height: 12),
            Text('This will add the app to your home screen for quick access!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipe Book'),
        actions: [
          // Install App Button - Only show if PWA is available
          if (_showInstallButton)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              tooltip: 'Install App',
              onPressed: _installPwa,
            ),
        ],
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