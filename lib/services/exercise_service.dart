import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exercise_model.dart';

class ExerciseService {
  static PregnancyExerciseData? _cachedData;

  /// Load pregnancy exercises from JSON file
  static Future<PregnancyExerciseData> loadExercises() async {
    // Return cached data if already loaded
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString(
        'assets/pregnancy_exercises.json',
      );

      // Parse the JSON
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Convert to model
      _cachedData = PregnancyExerciseData.fromJson(jsonData);

      return _cachedData!;
    } catch (e) {
      print('Error loading exercises: $e');
      rethrow;
    }
  }

  /// Clear cached data (useful for testing or refreshing)
  static void clearCache() {
    _cachedData = null;
  }
}
