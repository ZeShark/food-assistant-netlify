import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FoodAppState extends ChangeNotifier {
  static const String baseUrl = 'https://food-assistant-netlify.vercel.app/api';
  
  List<dynamic> _ingredients = [];
  List<dynamic> get ingredients => _ingredients;
  
  String _chatResponse = '';
  String get chatResponse => _chatResponse;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Recipe storage
  List<Map<String, dynamic>> _savedRecipes = [];
  List<Map<String, dynamic>> get savedRecipes => _savedRecipes;
  
  Map<String, dynamic>? _currentRecipe;
  Map<String, dynamic>? get currentRecipe => _currentRecipe;
  
  // User taste profile
  Map<String, dynamic> _tasteProfile = {
    'likedIngredients': [],
    'dislikedIngredients': [],
    'preferredCuisines': [],
    'preferredCookingTime': 'Medium (30-60 min)',
    'spiceLevel': 'Medium',
    'dietaryRestrictions': [],
  };
  Map<String, dynamic> get tasteProfile => _tasteProfile;

  // Available AI models
  final List<String> availableModels = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'microsoft/wizardlm-2-8x22b',
    'qwen/qwen-2.5-7b-instruct:free',
    'anthropic/claude-3-haiku',
  ];
  
  String _selectedModel = 'meta-llama/llama-3.1-8b-instruct:free';
  String get selectedModel => _selectedModel;

  // Initialize from shared preferences
  FoodAppState() {
    _loadPreferences();
    loadRecipes(); // Load from Supabase on startup
  }

  // Load saved data
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved recipes
    final recipesJson = prefs.getString('savedRecipes');
    if (recipesJson != null) {
      _savedRecipes = List<Map<String, dynamic>>.from(json.decode(recipesJson));
    }
    
    // Load current recipe
    final currentRecipeJson = prefs.getString('currentRecipe');
    if (currentRecipeJson != null) {
      _currentRecipe = Map<String, dynamic>.from(json.decode(currentRecipeJson));
    }
    
    // Load taste profile
    final tasteProfileJson = prefs.getString('tasteProfile');
    if (tasteProfileJson != null) {
      _tasteProfile = Map<String, dynamic>.from(json.decode(tasteProfileJson));
    }
    
    // Load selected model
    _selectedModel = prefs.getString('selectedModel') ?? 'meta-llama/llama-3.1-8b-instruct:free';
    
    notifyListeners();
  }

  // Save data to shared preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedRecipes', json.encode(_savedRecipes));
    await prefs.setString('currentRecipe', json.encode(_currentRecipe));
    await prefs.setString('tasteProfile', json.encode(_tasteProfile));
    await prefs.setString('selectedModel', _selectedModel);
  }

  void setSelectedModel(String model) {
    _selectedModel = model;
    _savePreferences();
    notifyListeners();
  }

  // Save current recipe
  void setCurrentRecipe(Map<String, dynamic> recipe) {
    _currentRecipe = recipe;
    _savePreferences();
    notifyListeners();
  }

  // Clear current recipe
  void clearCurrentRecipe() {
    _currentRecipe = null;
    _savePreferences();
    notifyListeners();
  }

  // Save recipe to recipe book (Supabase)
  Future<void> saveRecipe(Map<String, dynamic> recipe) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-recipes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'saveRecipe',
          'userId': 'demo-user',
          'recipe': recipe
        }),
      );
      
      if (response.statusCode == 200) {
        await loadRecipes(); // Reload to get the updated list
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recipe to Supabase: $e');
      }
      // Fallback to local storage if Supabase fails
      _saveRecipeLocally(recipe);
    }
  }

  // Local storage fallback
  void _saveRecipeLocally(Map<String, dynamic> recipe) {
    final recipeToSave = {
      ...recipe,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'savedAt': DateTime.now().toIso8601String(),
    };
    
    _savedRecipes.add(recipeToSave);
    _savePreferences();
    notifyListeners();
  }

  // Remove recipe from recipe book (Supabase)
  Future<void> removeRecipe(String recipeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-recipes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'removeRecipe',
          'userId': 'demo-user',
          'recipeId': recipeId
        }),
      );
      
      if (response.statusCode == 200) {
        await loadRecipes(); // Reload to get the updated list
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing recipe from Supabase: $e');
      }
      // Fallback to local removal
      _savedRecipes.removeWhere((recipe) => recipe['id'] == recipeId);
      _savePreferences();
      notifyListeners();
    }
  }

  // Load saved recipes from Supabase
  Future<void> loadRecipes() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-recipes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'getRecipes',
          'userId': 'demo-user'
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _savedRecipes = List<Map<String, dynamic>>.from(data['recipes'] ?? []);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recipes from Supabase: $e');
      }
    }
  }

  // Update taste profile
  void updateTasteProfile(Map<String, dynamic> updates) {
    _tasteProfile.addAll(updates);
    _savePreferences();
    notifyListeners();
  }

  // Like an ingredient (for taste profile)
  void likeIngredient(String ingredient) {
    if (!_tasteProfile['likedIngredients'].contains(ingredient)) {
      _tasteProfile['likedIngredients'].add(ingredient);
      _savePreferences();
      notifyListeners();
    }
  }

  // Dislike an ingredient (for taste profile)
  void dislikeIngredient(String ingredient) {
    if (!_tasteProfile['dislikedIngredients'].contains(ingredient)) {
      _tasteProfile['dislikedIngredients'].add(ingredient);
      _savePreferences();
      notifyListeners();
    }
  }

  // ========== EXISTING INGREDIENT METHODS ==========

  // Load ingredients from backend
  Future<void> loadIngredients({String? userId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-ingredients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'getIngredients',
          'userId': userId ?? 'demo-user'
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ingredients = data['ingredients'] ?? [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ingredients: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new ingredient
  Future<void> addIngredient(String name, {String category = 'uncategorized', String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-ingredients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'addIngredient',
          'name': name,
          'category': category,
          'userId': userId ?? 'demo-user'
        }),
      );
      
      if (response.statusCode == 200) {
        await loadIngredients(userId: userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding ingredient: $e');
      }
    }
  }

  // Update ingredient
  Future<void> updateIngredient(String id, {String? name, String? category, String? userId}) async {
    try {
      // Update local state immediately for better UX
      final index = _ingredients.indexWhere((ing) => ing['id'].toString() == id);
      if (index != -1) {
        final updatedIngredients = List<dynamic>.from(_ingredients);
        if (name != null) updatedIngredients[index]['name'] = name;
        if (category != null) updatedIngredients[index]['category'] = category;
        
        _ingredients = updatedIngredients;
        notifyListeners();
      }

      // Send update to server
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-ingredients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'updateIngredient',
          'ingredientId': id,
          'userId': userId ?? 'demo-user',
          if (name != null) 'name': name,
          if (category != null) 'category': category,
        }),
      );
      
      if (response.statusCode != 200) {
        await loadIngredients(userId: userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating ingredient: $e');
      }
      await loadIngredients(userId: userId);
    }
  }

  // Delete ingredient
  Future<void> deleteIngredient(String id, {String? userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supabase-ingredients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'removeIngredient',
          'ingredientId': id,
          'userId': userId ?? 'demo-user'
        }),
      );
      if (response.statusCode == 200) {
        await loadIngredients(userId: userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting ingredient: $e');
      }
    }
  }

  // Import multiple ingredients
  Future<void> importIngredients(List<String> ingredientNames, {String? userId}) async {
    try {
      for (final name in ingredientNames) {
        await addIngredient(name, userId: userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error importing ingredients: $e');
      }
    }
  }

  // ========== CHAT AND RECIPE METHODS ==========

  // Chat with AI assistant
  Future<void> sendMessage(String message, {List<Map<String, String>>? chatHistory}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'chatHistory': chatHistory ?? [],
          'model': _selectedModel,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _chatResponse = data['response'];
      } else {
        _chatResponse = 'Error: ${response.statusCode}';
      }
    } catch (e) {
      _chatResponse = 'Error connecting to assistant: $e';
      if (kDebugMode) {
        print('Error sending message: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recipe suggestions
  Future<Map<String, dynamic>> getRecipeSuggestions({
    String? cuisine, 
    String? diet, 
    String? time,
    List<String>? appliances,
    List<String>? ingredients,
    bool useTasteProfile = true,
  }) async {
    try {
      // Build request body with taste profile if enabled
      Map<String, dynamic> requestBody = {
        'ingredients': ingredients ?? [],
        'dietaryPreferences': diet,
        'mealType': time,
        'cuisine': cuisine,
        'model': _selectedModel,
      };

      // Add taste profile data if available and enabled
      if (useTasteProfile && _tasteProfile['likedIngredients'].isNotEmpty) {
        requestBody['preferredIngredients'] = _tasteProfile['likedIngredients'];
        requestBody['dislikedIngredients'] = _tasteProfile['dislikedIngredients'];
      }

      final response = await http.post(
        Uri.parse('$baseUrl/generateRecipe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Automatically save as current recipe
        setCurrentRecipe(data['recipe']);
        return {
          'success': true,
          'recipe': data['recipe']
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get suggestions: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error connecting to recipe service: $e'
      };
    }
  }
}