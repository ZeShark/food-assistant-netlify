import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodAppState extends ChangeNotifier {
  static const String baseUrl = 'https://foodassistant.netlify.app/api';
  
  List<dynamic> _ingredients = [];
  List<dynamic> get ingredients => _ingredients;
  
  String _chatResponse = '';
  String get chatResponse => _chatResponse;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Load ingredients from backend
  Future<void> loadIngredients() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/ingredients'));
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
  Future<void> addIngredient(String name, {String category = 'uncategorized'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'category': category,
        }),
      );
      
      if (response.statusCode == 200) {
        await loadIngredients();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding ingredient: $e');
      }
    }
  }

  // Update ingredient
Future<void> updateIngredient(String id, {String? name, String? category}) async {
  try {
    // Update local state immediately for better UX
    final index = _ingredients.indexWhere((ing) => ing['id'].toString() == id);
    if (index != -1) {
      // Create a copy to avoid direct mutation
      final updatedIngredients = List<dynamic>.from(_ingredients);
      if (name != null) updatedIngredients[index]['name'] = name;
      if (category != null) updatedIngredients[index]['category'] = category;
      
      _ingredients = updatedIngredients;
      notifyListeners(); // This triggers UI updates
    }

    // Send update to server
    final response = await http.put(
      Uri.parse('$baseUrl/ingredients/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (name != null) 'name': name,
        if (category != null) 'category': category,
      }),
    );
    
    if (response.statusCode != 200) {
      // If server update failed, revert local changes
      await loadIngredients();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error updating ingredient: $e');
    }
    // Revert local changes if update failed
    await loadIngredients();
  }
}

  // Delete ingredient
  Future<void> deleteIngredient(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/ingredients/$id'));
      if (response.statusCode == 200) {
        await loadIngredients(); // Reload the list
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting ingredient: $e');
      }
    }
  }

  // Import multiple ingredients
  Future<void> importIngredients(List<String> ingredientNames) async {
    try {
      final ingredients = ingredientNames.map((name) => {'name': name}).toList();
      
      final response = await http.post(
        Uri.parse('$baseUrl/ingredients/import'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ingredients': ingredients}),
      );
      
      if (response.statusCode == 200) {
        await loadIngredients(); // Reload the list
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error importing ingredients: $e');
      }
    }
  }

  // Chat with AI assistant
  Future<void> sendMessage(String message) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _chatResponse = data['response'];
      }
    } catch (e) {
      _chatResponse = 'Error connecting to assistant. Make sure the backend is running.';
      if (kDebugMode) {
        print('Error sending message: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get recipe suggestions
  Future<String> getRecipeSuggestions({
    String? cuisine, 
    String? diet, 
    String? time,
    List<String>? appliances,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cuisine': cuisine,
          'diet': diet,
          'time': time,
          'appliances': appliances,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['suggestions'] ?? 'No suggestions available';
      } else {
        return 'Failed to get suggestions: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to recipe service: $e';
    }
  }
}