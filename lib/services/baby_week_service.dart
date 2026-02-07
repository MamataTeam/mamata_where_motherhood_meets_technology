import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/baby_week.dart';

class BabyWeekService {
  static List<BabyWeek>? _cachedData;

  static Future<List<BabyWeek>> loadBabyWeeks() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final String response = await rootBundle.loadString('assets/baby_size_week.json');
      final List<dynamic> data = json.decode(response);
      
      _cachedData = data.map((json) => BabyWeek.fromJson(json)).toList();
      return _cachedData!;
    } catch (e) {
      print('Error loading baby weeks: $e');
      return [];
    }
  }

  static Future<BabyWeek?> getBabyWeekByNumber(int week) async {
    final babyWeeks = await loadBabyWeeks();
    try {
      return babyWeeks.firstWhere((bw) => bw.week == week);
    } catch (e) {
      print('No baby week found for week $week');
      return null;
    }
  }
}