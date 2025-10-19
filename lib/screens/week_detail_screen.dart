import 'package:flutter/material.dart';
import '../models/week_info.dart';


class WeekDetailScreen extends StatelessWidget {
  final WeekInfo weekInfo;

  const WeekDetailScreen({Key? key, required this.weekInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Week ${weekInfo.week} "),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFFFEE1DF), // soft pink background
      borderRadius: BorderRadius.circular(16),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        weekInfo.imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
            ),
          );
        },
      ),
    ),
  ),
),
const SizedBox(height: 16),

            Text("Baby Development", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(weekInfo.baby, style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 20),

            Text("Mom", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(weekInfo.mom, style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 20),

            Text("Helpful Tips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(weekInfo.helpfulTips, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
