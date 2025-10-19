import 'package:flutter/material.dart';
import '../models/week_info.dart';
import '../services/api_service.dart';
import 'week_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeekInfo? weekInfo;
  int currentWeek = 6;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    loadWeekInfo();
  }

  void loadWeekInfo() async {
    final progress = calculatePregnancyProgress();
    int currentWeekCalculated = progress['weeksElapsed'] + 1;

    WeekInfo? fetchedWeek = await ApiService.fetchWeekInfo(currentWeekCalculated);
    if (fetchedWeek != null) {
      setState(() {
        weekInfo = fetchedWeek;
        currentWeek = currentWeekCalculated;
      });
    }
  }

  String getTrimester(int week) {
  if (week <= 13) return "Trimester 1";
  if (week <= 27) return "Trimester 2";
  return "Trimester 3";
}

  Map<String, dynamic> calculatePregnancyProgress() {
    DateTime pregnancyStartDate = DateTime(2025, 4, 22); // Replace with actual start date + yesma last period ko date 
    DateTime now = DateTime.now();
    Duration diff = now.difference(pregnancyStartDate);

    int daysElapsed = diff.inDays;
    if (daysElapsed < 0) daysElapsed = 0;
    if (daysElapsed > 280) daysElapsed = 280;

    int weeksElapsed = daysElapsed ~/ 7;
    int daysInWeek = daysElapsed % 7;

    int totalPregnancyDays = 280;
    int daysRemaining = totalPregnancyDays - daysElapsed;

    int remainingWeeks = daysRemaining ~/ 7;
    int remainingDays = daysRemaining % 7;

    return {
      'daysElapsed': daysElapsed,
      'weeksElapsed': weeksElapsed,
      'daysInWeek': daysInWeek,
      'remainingWeeks': remainingWeeks,
      'remainingDays': remainingDays,
    };
  }

  @override
  Widget build(BuildContext context) {
    final progress = calculatePregnancyProgress();
    int daysElapsed = progress['daysElapsed'];
    int weeksElapsed = progress['weeksElapsed'];
    int daysInWeek = progress['daysInWeek'];
    int remainingWeeks = progress['remainingWeeks'];
    int remainingDays = progress['remainingDays'];

    return Scaffold(
      body: SafeArea(
        child: weekInfo == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, Nilisha!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 25),

                    // Main week card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFFFEE1DF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          SizedBox(height: 10),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              weekInfo!.imageUrl,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 300,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${weekInfo!.week} weeks",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right, size: 30),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WeekDetailScreen(weekInfo: weekInfo!),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 10),

                          if (isExpanded) ...[
                            SizedBox(height: 25),
                            Text("Baby Development", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(weekInfo!.baby, style: TextStyle(fontSize: 16)),
                            ),

                            SizedBox(height: 25),
                            Text("Mom", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(weekInfo!.mom, style: TextStyle(fontSize: 16)),
                            ),

                            SizedBox(height: 25),
                            Text("Helpful Tips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(weekInfo!.helpfulTips, style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 25),

                    // Progress and summary info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${weekInfo!.week} weeks"),
                              Text(getTrimester(weekInfo!.week)),

                            ],
                          ),
                          SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: weekInfo!.week / 40,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Before birth: $remainingWeeks weeks $remainingDays days"),
                              Text("Day $daysElapsed (${weeksElapsed}w + ${daysInWeek}d)"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 25),
                  ],
                ),
              ),
      ),
    );
  }
}
