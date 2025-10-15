import 'package:flutter/material.dart';
import 'screens/hospital_list_screen.dart';

void main() => runApp(HospitalRecommenderApp());

class HospitalRecommenderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hospital Recommender',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: HospitalListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
