import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/week_info.dart';

class WeekService {
  // Load all weeks from assets
  static Future<List<WeekInfo>> loadWeeks() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/pregnancy_weeks_info.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => WeekInfo.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load week info: $e');
    }
  }

  // Get a specific week by week number
  static Future<WeekInfo?> getWeekByNumber(int weekNumber) async {
    final weeks = await loadWeeks();
    try {
      return weeks.firstWhere((w) => w.week == weekNumber);
    } catch (e) {
      return null; // week not found
    }
  }
}
