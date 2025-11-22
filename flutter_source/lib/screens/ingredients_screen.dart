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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  String _selectedCategory = 'All';
  String _selectedAddCategory = 'uncategorized';
  String _searchQuery = '';
  List<dynamic> _filteredIngredients = [];

  // Common food categories
  final List<String> _commonCategories = [
    'uncategorized',
    'vegetable',
    'fruit',
    'meat',
    'poultry',
    'seafood',
    'dairy',
    'grains',
    'spices',
    'herbs',
    'oils',
    'condiments',
    'beverages',
    'frozen',
    'canned',
    'bakery',
    'snacks'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodAppState>().loadIngredients();
    });
  }

  void _updateFilteredIngredients(List<dynamic> ingredients) {
    setState(() {
      _filteredIngredients = ingredients.where((ingredient) {
        final matchesCategory = _selectedCategory == 'All' || 
            ingredient['category'] == _selectedCategory;
        final matchesSearch = _searchQuery.isEmpty ||
            ingredient['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _addIngredient() {
    final name = _ingredientController.text.trim();
    if (name.isNotEmpty) {
      if (mounted) {
        context.read<FoodAppState>().addIngredient(
          name, 
          category: _selectedAddCategory
        ).then((_) {
          _ingredientController.clear();
          _categoryController.clear();
          FocusScope.of(context).unfocus();
        });
      }
    }
  }

  void _importIngredients() {
    final text = _importController.text.trim();
    if (text.isNotEmpty) {
      final ingredients = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (mounted) {
        context.read<FoodAppState>().importIngredients(ingredients);
        _importController.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., spices, frozen, etc.',
          ),
          onSubmitted: (_) => _addCustomCategory(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _addCustomCategory,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addCustomCategory() {
    final newCategory = _categoryController.text.trim();
    if (newCategory.isNotEmpty && !_commonCategories.contains(newCategory.toLowerCase())) {
      setState(() {
        _commonCategories.add(newCategory.toLowerCase());
        _selectedAddCategory = newCategory.toLowerCase();
      });
      _categoryController.clear();
      Navigator.pop(context);
    } else if (newCategory.isNotEmpty) {
      // Category already exists
      setState(() {
        _selectedAddCategory = newCategory.toLowerCase();
      });
      _categoryController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FoodAppState>();

    // Update filtered list when ingredients change
    if (_filteredIngredients.isEmpty || _filteredIngredients.length != appState.ingredients.length) {
      _updateFilteredIngredients(appState.ingredients);
    }

    // Get unique categories from current ingredients
    final availableCategories = <String>{};
    for (final ingredient in appState.ingredients) {
      availableCategories.add(ingredient['category'] ?? 'uncategorized');
    }
    final allCategories = ['All', ...availableCategories.toList()..sort()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ingredients'),
        actions: [
          if (appState.ingredients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearAllDialog(context, appState);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Ingredients',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _updateFilteredIngredients(appState.ingredients);
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _updateFilteredIngredients(appState.ingredients);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Filter
                  Row(
                    children: [
                      const Text('Filter by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: allCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue!;
                              _updateFilteredIngredients(appState.ingredients);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Add ingredient section
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Ingredient Name
                  TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      hintText: 'e.g., Chicken Breast, Tomatoes, etc.',
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Selection
                  Row(
                    children: [
                      const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedAddCategory,
                          isExpanded: true,
                          items: _commonCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAddCategory = newValue!;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _showAddCategoryDialog,
                        tooltip: 'Add new category',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ingredientController.text.trim().isEmpty ? null : _addIngredient,
                      child: const Text('Add Ingredient'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bulk Import Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulk Import',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add multiple ingredients (comma separated). They will be added as "uncategorized".',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _importController,
                    decoration: InputDecoration(
                      labelText: 'Ingredients (comma separated)',
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
          ),
          
          // Results count
          if (_filteredIngredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${_filteredIngredients.length} of ${appState.ingredients.length} ingredients',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (_selectedCategory != 'All')
                    Chip(
                      label: Text(_selectedCategory),
                      backgroundColor: Colors.blue[50],
                    ),
                ],
              ),
            ),
          
          // Ingredients list
          Expanded(
            child: appState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredIngredients.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.kitchen, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No ingredients found!\nTry changing your search or add some ingredients.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = _filteredIngredients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: _getCategoryIcon(ingredient['category']),
                              title: Text(
                                ingredient['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${ingredient['category'] ?? 'uncategorized'}'),
                                  if (ingredient['quantity'] != null && ingredient['quantity'] > 1)
                                    Text('Quantity: ${ingredient['quantity']} ${ingredient['unit']}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteDialog(context, ingredient, appState);
                                },
                              ),
                              onTap: () {
                                _showEditDialog(context, ingredient, appState);
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

  Widget _getCategoryIcon(String? category) {
    final cat = category?.toLowerCase() ?? 'uncategorized';
    switch (cat) {
      case 'vegetable':
        return const Icon(Icons.eco, color: Colors.green);
      case 'fruit':
        return const Icon(Icons.apple, color: Colors.red);
      case 'meat':
      case 'poultry':
        return const Icon(Icons.set_meal, color: Colors.brown);
      case 'seafood':
        return const Icon(Icons.waves, color: Colors.blue);
      case 'dairy':
        return const Icon(Icons.local_drink, color: Colors.yellow);
      case 'grains':
        return const Icon(Icons.grain, color: Colors.orange);
      case 'spices':
      case 'herbs':
        return const Icon(Icons.spa, color: Colors.purple);
      case 'oils':
      case 'condiments':
        return const Icon(Icons.opacity, color: Colors.amber);
      case 'beverages':
        return const Icon(Icons.local_cafe, color: Colors.brown);
      case 'frozen':
        return const Icon(Icons.ac_unit, color: Colors.blue);
      case 'canned':
        return const Icon(Icons.inventory_2, color: Colors.orange);
      case 'bakery':
        return const Icon(Icons.bakery_dining, color: Colors.brown);
      case 'snacks':
        return const Icon(Icons.cookie, color: Colors.orange);
      default:
        return const Icon(Icons.kitchen, color: Colors.grey);
    }
  }

  void _showClearAllDialog(BuildContext context, FoodAppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Ingredients?'),
        content: const Text('This will remove all your ingredients. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Add clear all functionality here
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, dynamic ingredient, FoodAppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ingredient?'),
        content: Text('Are you sure you want to delete "${ingredient['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) {
                appState.deleteIngredient(ingredient['id'].toString());
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic ingredient, FoodAppState appState) {
    final nameController = TextEditingController(text: ingredient['name']);
    final categoryController = TextEditingController(text: ingredient['category']);
    String selectedCategory = ingredient['category'] ?? 'uncategorized';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Category: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: _commonCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedCategory = newValue!;
                        });
                      },
                    ),
                  ),
                ],
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
                  if (mounted) {
                    appState.updateIngredient(
                      ingredient['id'].toString(),
                      name: newName,
                      category: selectedCategory,
                    ).then((_) {
                      Navigator.pop(context);
                    });
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}