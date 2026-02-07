import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/week_image.dart';

class WeekImageService {
  static List<WeekImage>? _cachedImages;

  static Future<List<WeekImage>> loadWeekImages() async {
    if (_cachedImages != null) {
      return _cachedImages!;
    }

    try {
      final String response = await rootBundle.loadString('assets/week_images.json');
      final List<dynamic> data = json.decode(response);
      
      _cachedImages = data.map((json) => WeekImage.fromJson(json)).toList();
      return _cachedImages!;
    } catch (e) {
      print('Error loading week images: $e');
      return [];
    }
  }

  static Future<String?> getImageUrlForWeek(int week) async {
    final images = await loadWeekImages();
    try {
      final weekImage = images.firstWhere((img) => img.week == week);
      return weekImage.imageUrl;
    } catch (e) {
      print('No image found for week $week');
      return null;
    }
  }
}