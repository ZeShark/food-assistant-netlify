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
  String _recipeSuggestions = '';
  bool _isLoadingSuggestions = false;
  
  // Enhanced cuisine list with countries
  final List<String> cuisines = [
    'Any cuisine',
    'Italian', 'French', 'Spanish', 'Greek', 'Mediterranean',
    'Mexican', 'Brazilian', 'Peruvian', 'Argentinian',
    'Chinese', 'Japanese', 'Thai', 'Vietnamese', 'Indian', 'Korean',
    'American', 'British', 'German', 'Middle Eastern',
    'African', 'Caribbean', 'Thai', 'Moroccan'
  ];
  
  // Enhanced time options
  final List<String> times = [
    'Quick (under 30 min)',
    'Medium (30-60 min)', 
    'Long (1-2 hours)',
    'Time doesn\'t matter',
    'Very quick (under 15 min)'
  ];

  // Appliances selection
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

  Future<void> _getRecipeSuggestions(BuildContext context) async {
    final appState = context.read<FoodAppState>();
    
    setState(() {
      _isLoadingSuggestions = true;
      _recipeSuggestions = '';
    });

    try {
      // Get selected appliances
      final selectedAppliances = _appliances.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final suggestions = await appState.getRecipeSuggestions(
        cuisine: _selectedCuisine == 'Any cuisine' ? null : _selectedCuisine,
        time: _selectedTime,
        appliances: selectedAppliances,
      );
      
      setState(() {
        _recipeSuggestions = suggestions;
      });
    } catch (e) {
      setState(() {
        _recipeSuggestions = 'Error getting suggestions: $e';
      });
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  Widget _getCategoryIcon(String? category) {
    final cat = category?.toLowerCase() ?? 'uncategorized';
    switch (cat) {
      case 'vegetable':
        return const Icon(Icons.eco, color: Colors.green, size: 16);
      case 'fruit':
        return const Icon(Icons.apple, color: Colors.red, size: 16);
      case 'meat':
      case 'poultry':
        return const Icon(Icons.set_meal, color: Colors.brown, size: 16);
      case 'seafood':
        return const Icon(Icons.waves, color: Colors.blue, size: 16);
      case 'dairy':
        return const Icon(Icons.local_drink, color: Colors.yellow, size: 16);
      case 'grains':
        return const Icon(Icons.grain, color: Colors.orange, size: 16);
      case 'spices':
      case 'herbs':
        return const Icon(Icons.spa, color: Colors.purple, size: 16);
      case 'oils':
      case 'condiments':
        return const Icon(Icons.opacity, color: Colors.amber, size: 16);
      case 'beverages':
        return const Icon(Icons.local_cafe, color: Colors.brown, size: 16);
      case 'frozen':
        return const Icon(Icons.ac_unit, color: Colors.blue, size: 16);
      case 'canned':
        return const Icon(Icons.inventory_2, color: Colors.orange, size: 16);
      case 'bakery':
        return const Icon(Icons.bakery_dining, color: Colors.brown, size: 16);
      case 'snacks':
        return const Icon(Icons.cookie, color: Colors.orange, size: 16);
      default:
        return const Icon(Icons.kitchen, color: Colors.grey, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
      ),
      body: Column(
        children: [
          // Filters Card
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
                  
                  // Cuisine Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCuisine,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine Type',
                      border: OutlineInputBorder(),
                    ),
                    items: cuisines.map((cuisine) => DropdownMenuItem(
                      value: cuisine,
                      child: Text(cuisine),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCuisine = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Time Dropdown
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
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Appliances Section
                  const Text(
                    'Available Appliances:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _appliances.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() {
                            _appliances[entry.key] = selected;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Get Suggestions Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: appState.ingredients.isEmpty || _isLoadingSuggestions 
                          ? null 
                          : () => _getRecipeSuggestions(context),
                      child: _isLoadingSuggestions
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Get Recipe Suggestions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Recipe Suggestions Display
          if (_recipeSuggestions.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipe Suggestions:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(_recipeSuggestions),
                  ],
                ),
              ),
            ),
          
          // Current ingredients preview with icons
          Expanded(
            child: appState.ingredients.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Add some ingredients first\nto get recipe suggestions!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Your Ingredients:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
                              trailing: Text(
                                '${ingredient['quantity'] ?? 1} ${ingredient['unit'] ?? 'unit'}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}