import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/week_info.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; 

  static Future<WeekInfo?> fetchWeekInfo(int weekNumber) async {
    final url = Uri.parse('$baseUrl/get-week/$weekNumber');
    try {
      final response = await http.get(url);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['error'] == null) {
          return WeekInfo.fromJson(jsonData);
        } else {
          print('Week not found: ${jsonData['error']}');
          return null;
        }
      } else {
        print('Failed to fetch data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception caught: $e');
      return null;
    }
  }
}
