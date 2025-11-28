import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String? _selectedCuisine;
  String? _selectedTime;
  bool _isGenerating = false;
  bool _useTasteProfile = true;
  
  final List<String> cuisines = [
    'Any cuisine', 'Italian', 'French', 'Spanish', 'Greek', 'Mediterranean',
    'Mexican', 'Brazilian', 'Chinese', 'Japanese', 'Thai', 'Indian', 'Korean',
    'American', 'British', 'Middle Eastern', 'African', 'Caribbean', 'Moroccan'
  ];
  
  final List<String> times = [
    'Quick (under 30 min)', 'Medium (30-60 min)', 'Long (1-2 hours)',
    'Time doesn\'t matter', 'Very quick (under 15 min)'
  ];

  final Map<String, bool> _appliances = {
    'Oven': true, 'Stovetop': true, 'Microwave': true, 'Blender': true,
    'Air Fryer': false, 'Slow Cooker': false, 'Pressure Cooker': false,
    'Grill': false, 'Food Processor': false, 'Stand Mixer': false,
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();
    final currentRecipe = appState.currentRecipe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        actions: [
          DropdownButton<String>(
            value: appState.selectedModel,
            onChanged: (newModel) {
              if (newModel != null) appState.setSelectedModel(newModel);
            },
            items: appState.availableModels.map((model) {
              final displayName = model.split('/').last;
              return DropdownMenuItem(
                value: model,
                child: Text(
                  displayName.length > 12 
                    ? '${displayName.substring(0, 12)}...' 
                    : displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible filters section
          ExpansionTile(
            title: const Text('Recipe Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            initiallyExpanded: currentRecipe == null, // Auto-expand if no recipe
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Taste profile toggle
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 16),
                        const SizedBox(width: 8),
                        const Text('Use taste profile'),
                        const Spacer(),
                        Switch(
                          value: _useTasteProfile,
                          onChanged: (value) => setState(() => _useTasteProfile = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Cuisine Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCuisine,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine Type',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: cuisines.map((cuisine) => DropdownMenuItem(
                        value: cuisine,
                        child: Text(cuisine, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedCuisine = value),
                    ),
                    const SizedBox(height: 12),
                    
                    // Time Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTime,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Cooking Time',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: times.map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedTime = value),
                    ),
                    const SizedBox(height: 12),
                    
                    // Appliances Section
                    const Text('Available Appliances:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _appliances.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key, style: const TextStyle(fontSize: 12)),
                          selected: entry.value,
                          onSelected: (selected) => setState(() => _appliances[entry.key] = selected),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: appState.ingredients.isEmpty || _isGenerating 
                            ? null 
                            : () => _generateRecipe(context),
                        child: _isGenerating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('Generating...'),
                                ],
                              )
                            : const Text('Get Recipe Suggestions'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          
          // Current Recipe Display - Scrollable
          if (currentRecipe != null) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Current Recipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded( // Make recipe scrollable
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                currentRecipe['title'] ?? 'Generated Recipe',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bookmark_add, color: Colors.blue),
                              onPressed: () {
                                appState.saveRecipe(currentRecipe);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Recipe saved!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        if (currentRecipe['description'] != null) ...[
                          Text(currentRecipe['description']!),
                          const SizedBox(height: 12),
                        ],
                        
                        const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._formatIngredients(currentRecipe['ingredients']),
                        
                        const SizedBox(height: 12),
                        const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._formatInstructions(currentRecipe['instructions']),
                        
                        if (currentRecipe['cookingTime'] != null || currentRecipe['difficulty'] != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (currentRecipe['cookingTime'] != null)
                                Chip(label: Text('⏱️ ${currentRecipe['cookingTime']!}')),
                              if (currentRecipe['difficulty'] != null)
                                Chip(label: Text('📊 ${currentRecipe['difficulty']!}')),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Ingredients list when no recipe
            Expanded(
              child: appState.ingredients.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Add ingredients first\nto get recipe suggestions!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _buildIngredientsList(appState),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientsList(FoodAppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Your Ingredients:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: appState.ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = appState.ingredients[index];
              return ListTile(
                leading: _getCategoryIcon(ingredient['category']),
                title: Text(ingredient['name']),
                subtitle: Text('Category: ${ingredient['category'] ?? 'uncategorized'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 18),
                      onPressed: () {
                        appState.likeIngredient(ingredient['name']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Liked ${ingredient['name']}!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down, size: 18),
                      onPressed: () {
                        appState.dislikeIngredient(ingredient['name']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Disliked ${ingredient['name']}!')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _getCategoryIcon(String? category) {
    final cat = category?.toLowerCase() ?? 'uncategorized';
    switch (cat) {
      case 'vegetable': return const Icon(Icons.eco, color: Colors.green, size: 16);
      case 'fruit': return const Icon(Icons.apple, color: Colors.red, size: 16);
      case 'meat': case 'poultry': return const Icon(Icons.set_meal, color: Colors.brown, size: 16);
      case 'seafood': return const Icon(Icons.waves, color: Colors.blue, size: 16);
      case 'dairy': return const Icon(Icons.local_drink, color: Colors.yellow, size: 16);
      case 'grains': return const Icon(Icons.grain, color: Colors.orange, size: 16);
      case 'spices': case 'herbs': return const Icon(Icons.spa, color: Colors.purple, size: 16);
      case 'oils': case 'condiments': return const Icon(Icons.opacity, color: Colors.amber, size: 16);
      case 'beverages': return const Icon(Icons.local_cafe, color: Colors.brown, size: 16);
      case 'frozen': return const Icon(Icons.ac_unit, color: Colors.blue, size: 16);
      case 'canned': return const Icon(Icons.inventory_2, color: Colors.orange, size: 16);
      case 'bakery': return const Icon(Icons.bakery_dining, color: Colors.brown, size: 16);
      case 'snacks': return const Icon(Icons.cookie, color: Colors.orange, size: 16);
      default: return const Icon(Icons.kitchen, color: Colors.grey, size: 16);
    }
  }

  Future<void> _generateRecipe(BuildContext context) async {
    final appState = context.read<FoodAppState>();
    
    setState(() => _isGenerating = true);

    try {
      final currentIngredients = appState.ingredients.map((ing) => ing['name'].toString()).toList();
      final selectedAppliances = _appliances.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

      final result = await appState.getRecipeSuggestions(
        cuisine: _selectedCuisine,
        diet: null,
        time: _selectedTime,
        appliances: selectedAppliances,
        ingredients: currentIngredients,
        useTasteProfile: _useTasteProfile,
      );

      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}