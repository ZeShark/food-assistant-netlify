import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodAppState extends ChangeNotifier {
  static const String baseUrl = 'https://food-assistant-netlify.vercel.app/api';
  
  List<dynamic> _ingredients = [];
  List<dynamic> get ingredients => _ingredients;
  
  String _chatResponse = '';
  String get chatResponse => _chatResponse;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

    // Available AI models
  final List<String> availableModels = [
    'google/gemini-flash-1.5',
    'anthropic/claude-3-haiku',
    'meta-llama/llama-3.1-8b-instruct:free',
    'microsoft/wizardlm-2-8x22b',
  ];
  
  String _selectedModel = 'google/gemini-flash-1.5';
  String get selectedModel => _selectedModel;
  
  void setSelectedModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

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
          'userId': userId ?? 'demo-user' // DEFAULT USER ID
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _ingredients = data['ingredients'];
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
          'userId': userId ?? 'demo-user' // DEFAULT USER ID
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
          'userId': userId ?? 'demo-user', // DEFAULT USER ID
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
          'userId': userId ?? 'demo-user' // DEFAULT USER ID
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

    // Chat with AI assistant - UPDATED with model selection
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
          'model': _selectedModel, // Add selected model
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

  // Get recipe suggestions - UPDATED with model selection
  Future<Map<String, dynamic>> getRecipeSuggestions({
    String? cuisine, 
    String? diet, 
    String? time,
    List<String>? appliances,
    List<String>? ingredients,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generateRecipe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ingredients': ingredients ?? [],
          'dietaryPreferences': diet,
          'mealType': time,
          'cuisine': cuisine,
          'model': _selectedModel, // Add selected model
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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