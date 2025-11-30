import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class EnhancedRecipesScreen extends StatefulWidget {
  const EnhancedRecipesScreen({super.key});

  @override
  State<EnhancedRecipesScreen> createState() => _EnhancedRecipesScreenState();
}

class _EnhancedRecipesScreenState extends State<EnhancedRecipesScreen> {
  String? _selectedCuisine;
  String? _selectedTime;
  String? _selectedBase;
  bool _isGenerating = false;
  bool _useTasteProfile = true;
  bool _allowRandomBase = false;
  
  final List<String> cuisines = [
    'Any cuisine', 'Italian', 'French', 'Spanish', 'Greek', 'Mediterranean',
    'Mexican', 'Brazilian', 'Chinese', 'Japanese', 'Thai', 'Indian', 'Korean',
    'American', 'British', 'Middle Eastern', 'African', 'Caribbean', 'Moroccan'
  ];
  
  final List<String> times = [
    'Quick (under 30 min)', 'Medium (30-60 min)', 'Long (1-2 hours)',
    'Time doesn\'t matter', 'Very quick (under 15 min)', 'Over 2 hours', 'All day cooking'
  ];

  final Map<String, bool> _appliances = {
    'Oven': true,
    'Stovetop': true,
    'Microwave': true,
    'Blender': true,
    'Air Fryer': false,
    'Slow Cooker': false,
    'Pressure Cooker': false,
    'Grill': false,
    'Food Processor': false,
    'Stand Mixer': false,
  };

  final TextEditingController _customCuisineController = TextEditingController();
  final TextEditingController _customApplianceController = TextEditingController();

  // Get available meat/poultry bases from ingredients
  List<String> _getAvailableBases(FoodAppState appState) {
    final meatPoultryIngredients = appState.ingredients.where((ingredient) {
      final category = ingredient['category']?.toString().toLowerCase();
      return category == 'meat' || category == 'poultry';
    }).map((ingredient) => ingredient['name'].toString()).toList();

    final standardBases = [
     'No specific base'
    ];

    // Combine available meat/poultry with standard bases
    return [...meatPoultryIngredients, ...standardBases];
  }

  void _addCustomCuisine(BuildContext context) {
    if (_customCuisineController.text.trim().isNotEmpty) {
      final appState = context.read<FoodAppState>();
      appState.addCustomCuisine(_customCuisineController.text.trim());
      _customCuisineController.clear();
    }
  }

  void _addCustomAppliance(BuildContext context) {
    if (_customApplianceController.text.trim().isNotEmpty) {
      final appState = context.read<FoodAppState>();
      appState.addCustomAppliance(_customApplianceController.text.trim());
      _customApplianceController.clear();
    }
  }

  void _removeCustomCuisine(String cuisine, BuildContext context) {
    final appState = context.read<FoodAppState>();
    appState.removeCustomCuisine(cuisine);
  }

  void _removeCustomAppliance(String appliance, BuildContext context) {
    final appState = context.read<FoodAppState>();
    appState.removeCustomAppliance(appliance);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();
    final currentRecipe = appState.currentRecipe;
    final availableBases = _getAvailableBases(appState);
    final customCuisines = appState.customCuisines;
    final customAppliances = appState.customAppliances;

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
          // Enhanced Filters Card
          Expanded(
            child: ListView(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recipe Filters',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        
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
                        const SizedBox(height: 16),

                        // Base selection - based on available meat/poultry
                        DropdownButtonFormField<String>(
                          value: _selectedBase,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Preferred Base',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No preference (use any base)'),
                            ),
                            ...availableBases.map((base) => DropdownMenuItem(
                              value: base,
                              child: Text(base),
                            )),
                          ],
                          onChanged: (value) => setState(() => _selectedBase = value),
                        ),
                        const SizedBox(height: 8),
                        
                        // Random base option
                        CheckboxListTile(
                          title: const Text('Allow creative base combinations'),
                          value: _allowRandomBase,
                          onChanged: (value) => setState(() => _allowRandomBase = value ?? false),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        // Cuisine selection (multiple)
                        const Text('Cuisine Style(s):', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        
                        // Selected cuisines chips
                        if (customCuisines.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            children: customCuisines.map((cuisine) {
                              return Chip(
                                label: Text(cuisine),
                                onDeleted: () => _removeCustomCuisine(cuisine, context),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        
                        // Cuisine dropdown and custom input
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: null,
                                decoration: const InputDecoration(
                                  labelText: 'Add Cuisine',
                                  border: OutlineInputBorder(),
                                ),
                                items: cuisines.map((cuisine) => DropdownMenuItem(
                                  value: cuisine,
                                  child: Text(cuisine),
                                )).toList(),
                                onChanged: (value) {
                                  if (value != null && value != 'Any cuisine' && !customCuisines.contains(value)) {
                                    appState.addCustomCuisine(value);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Custom cuisine input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customCuisineController,
                                decoration: const InputDecoration(
                                  labelText: 'Custom Cuisine',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _addCustomCuisine(context),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addCustomCuisine(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Time selection
                        DropdownButtonFormField<String>(
                          value: _selectedTime,
                          decoration: const InputDecoration(
                            labelText: 'Cooking Time',
                            border: OutlineInputBorder(),
                          ),
                          items: times.map((time) => DropdownMenuItem(
                            value: time,
                            child: Text(time),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedTime = value),
                        ),
                        const SizedBox(height: 16),

                        // Appliances section
                        const Text('Available Appliances:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        
                        // Standard appliances
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
                        
                        // Custom appliances
                        if (customAppliances.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: customAppliances.map((appliance) {
                              return Chip(
                                label: Text(appliance, style: const TextStyle(fontSize: 12)),
                                onDeleted: () => _removeCustomAppliance(appliance, context),
                              );
                            }).toList(),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        
                        // Custom appliance input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customApplianceController,
                                decoration: const InputDecoration(
                                  labelText: 'Add Custom Appliance',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _addCustomAppliance(context),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _addCustomAppliance(context),
                            ),
                          ],
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
                      ],
                    ),
                  ),
                ),

                // Current Recipe Display
                if (currentRecipe != null) ...[
                  Padding(
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
                            
                            // Show preview and "View Full Recipe" button
                            const Text('Ingredients Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ..._formatIngredientsPreview(currentRecipe['ingredients']),
                            
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _showFullRecipe(context, currentRecipe),
                                child: const Text('View Full Recipe'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _formatIngredientsPreview(dynamic ingredients) {
    if (ingredients == null) return [const Text('No ingredients listed')];
    if (ingredients is List) {
      // Show only first 3 ingredients as preview
      final previewIngredients = ingredients.take(3).toList();
      return [
        ...previewIngredients.map((ing) {
          if (ing is Map) {
            return Text('• ${ing['name'] ?? 'Unknown'}: ${ing['amount'] ?? 'Some'}');
          } else {
            return Text('• $ing');
          }
        }).toList(),
        if (ingredients.length > 3) 
          Text('... and ${ingredients.length - 3} more ingredients', style: TextStyle(color: Colors.grey[600])),
      ];
    }
    return [const Text('No ingredients listed')];
  }

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

  Future<void> _generateRecipe(BuildContext context) async {
    final appState = context.read<FoodAppState>();
    
    setState(() => _isGenerating = true);

    try {
      final currentIngredients = appState.ingredients.map((ing) => ing['name'].toString()).toList();
      
      // Combine standard and custom appliances
      final selectedAppliances = [
        ..._appliances.entries.where((entry) => entry.value).map((entry) => entry.key),
        ...appState.customAppliances,
      ];

      // Combine selected cuisines
      final allCuisines = [...appState.customCuisines];
      if (_selectedCuisine != null && _selectedCuisine != 'Any cuisine' && !allCuisines.contains(_selectedCuisine)) {
        allCuisines.add(_selectedCuisine!);
      }

      final result = await appState.getRecipeSuggestions(
        cuisine: allCuisines.isNotEmpty ? allCuisines.join(' + ') : null,
        diet: null,
        time: _selectedTime,
        appliances: selectedAppliances,
        ingredients: currentIngredients,
        base: _selectedBase,
        allowRandomBase: _allowRandomBase,
        useTasteProfile: _useTasteProfile,
      );

      if (result['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  void dispose() {
    _customCuisineController.dispose();
    _customApplianceController.dispose();
    super.dispose();
  }
}