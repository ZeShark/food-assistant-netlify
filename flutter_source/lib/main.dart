import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FoodAppState(),
      child: const FoodAssistantApp(),
    ),
  );
}