import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/nutrition_model.dart';

class NutritionService {
  static Future<PregnancyNutritionData> loadNutrition() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/pregnancy_nutrition.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return PregnancyNutritionData.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load nutrition data: $e');
    }
  }
}
