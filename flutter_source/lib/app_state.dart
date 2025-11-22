import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FoodAppState extends ChangeNotifier {
  static const String baseUrl = 'http://192.168.0.166:3000';
  
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
        await loadIngredients(); // Reload the list
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding ingredient: $e');
      }
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
  Future<String> getRecipeSuggestions({String? cuisine, String? diet, String? time}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recipes/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cuisine': cuisine,
          'diet': diet,
          'time': time,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['suggestions'];
      }
      return 'Failed to get suggestions';
    } catch (e) {
      return 'Error connecting to recipe service';
    }
  }
}