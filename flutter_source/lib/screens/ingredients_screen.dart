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
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'vegetable';
  
  // Updated categories without frozen
  final List<String> categories = [
    'vegetable', 'fruit', 'meat', 'poultry', 'seafood', 'dairy',
    'grains', 'spices', 'herbs', 'oils', 'condiments', 'beverages',
    'canned', 'bakery', 'snacks', 'other'
  ];

  void _addIngredient() {
    final name = _ingredientController.text.trim();
    if (name.isNotEmpty) {
      context.read<FoodAppState>().addIngredient(name, category: _selectedCategory);
      _ingredientController.clear();
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Ingredients'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search...'),
          onChanged: (value) {
            // You can implement search functionality here
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement search
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final TextEditingController importController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Ingredients'),
        content: TextField(
          controller: importController,
          decoration: const InputDecoration(
            hintText: 'Enter ingredients separated by commas',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = importController.text.trim();
              if (text.isNotEmpty) {
                final ingredients = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                context.read<FoodAppState>().importIngredients(ingredients);
                Navigator.pop(context);
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showTagsDialog(Map<String, dynamic> ingredient) {
    bool isFrozen = ingredient['tags']?.contains('frozen') ?? false;
    bool needsRefrigeration = ingredient['tags']?.contains('refrigerated') ?? false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Tags for ${ingredient['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Frozen'),
                  value: isFrozen,
                  onChanged: (value) {
                    setState(() => isFrozen = value ?? false);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Refrigerated'),
                  value: needsRefrigeration,
                  onChanged: (value) {
                    setState(() => needsRefrigeration = value ?? false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  List<String> tags = [];
                  if (isFrozen) tags.add('frozen');
                  if (needsRefrigeration) tags.add('refrigerated');
                  
                  context.read<FoodAppState>().updateIngredient(
                    ingredient['id'].toString(),
                    tags: tags,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditIngredientDialog(BuildContext context, Map<String, dynamic> ingredient) {
    final TextEditingController nameController = TextEditingController(text: ingredient['name']);
    String category = ingredient['category'] ?? 'other';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ingredient Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              items: categories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  category = value;
                }
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                context.read<FoodAppState>().updateIngredient(
                  ingredient['id'].toString(),
                  name: newName,
                  category: category, tags: [],
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteIngredientDialog(BuildContext context, Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete "${ingredient['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<FoodAppState>().deleteIngredient(ingredient['id'].toString());
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String? category) {
    final cat = category?.toLowerCase() ?? 'uncategorized';
    switch (cat) {
      case 'vegetable': return const Icon(Icons.eco, color: Colors.green, size: 16);
      case 'fruit': return const Icon(Icons.apple, color: Colors.red, size: 16);
      case 'meat': return const Icon(Icons.set_meal, color: Colors.brown, size: 16);
      case 'poultry': return const Icon(Icons.egg, color: Colors.orange, size: 16);
      case 'seafood': return const Icon(Icons.waves, color: Colors.blue, size: 16);
      case 'dairy': return const Icon(Icons.local_drink, color: Colors.yellow, size: 16);
      case 'grains': return const Icon(Icons.grain, color: Colors.orange, size: 16);
      case 'spices': case 'herbs': return const Icon(Icons.spa, color: Colors.purple, size: 16);
      case 'oils': case 'condiments': return const Icon(Icons.opacity, color: Colors.amber, size: 16);
      case 'beverages': return const Icon(Icons.local_cafe, color: Colors.brown, size: 16);
      case 'canned': return const Icon(Icons.inventory_2, color: Colors.orange, size: 16);
      case 'bakery': return const Icon(Icons.bakery_dining, color: Colors.brown, size: 16);
      case 'snacks': return const Icon(Icons.cookie, color: Colors.orange, size: 16);
      default: return const Icon(Icons.kitchen, color: Colors.grey, size: 16);
    }
  }

  @override
  void initState() {
    super.initState();
    // Load ingredients when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodAppState>().loadIngredients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ingredients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showImportDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact add ingredient section
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      labelText: 'Add Ingredient',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addIngredient,
                      ),
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: categories.map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Ingredients list - takes most space
          Expanded(
            child: appState.ingredients.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.kitchen, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No ingredients yet!\nAdd some ingredients to get started.',
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
                        leading: _getCategoryIcon(ingredient['category']),
                        title: Text(ingredient['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category: ${ingredient['category'] ?? 'uncategorized'}'),
                            if (ingredient['tags'] != null && (ingredient['tags'] as List).isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: (ingredient['tags'] as List).map<Widget>((tag) {
                                  return Chip(
                                    label: Text(tag),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.local_offer, size: 20),
                              onPressed: () => _showTagsDialog(ingredient),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditIngredientDialog(context, ingredient),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => _showDeleteIngredientDialog(context, ingredient),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}