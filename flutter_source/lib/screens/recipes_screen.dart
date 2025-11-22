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
  
  final List<String> cuisines = [
    'Italian', 'Mexican', 'Asian', 'Indian', 'Mediterranean', 'American'
  ];
  
  final List<String> times = [
    '15 minutes', '30 minutes', '1 hour', '2 hours'
  ];

  Future<void> _getRecipeSuggestions(BuildContext context) async {
    final appState = context.read<FoodAppState>();
    
    setState(() {
      _isLoadingSuggestions = true;
      _recipeSuggestions = '';
    });

    try {
      final suggestions = await appState.getRecipeSuggestions(
        cuisine: _selectedCuisine,
        time: _selectedTime,
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCuisine,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any cuisine')),
                      ...cuisines.map((cuisine) => DropdownMenuItem(
                        value: cuisine,
                        child: Text(cuisine),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCuisine = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTime,
                    decoration: const InputDecoration(
                      labelText: 'Cooking Time',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Any time')),
                      ...times.map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
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
          
          // Current ingredients preview
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
                              leading: const Icon(Icons.kitchen),
                              title: Text(ingredient['name']),
                              subtitle: Text('Category: ${ingredient['category'] ?? 'uncategorized'}'),
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