import 'package:flutter/material.dart';
import '../models/week_info.dart';
import '../services/week_service.dart';

class WeekDetailScreen extends StatefulWidget {
  final WeekInfo weekInfo;

  const WeekDetailScreen({Key? key, required this.weekInfo}) : super(key: key);

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  // Gradient colors
  static const primaryColor = Color(0xFF667EEA);
  static const secondaryColor = Color(0xFF764BA2);

  late WeekInfo currentWeekInfo;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentWeekInfo = widget.weekInfo;
  }

  Future<void> _loadWeek(int weekNumber) async {
    if (weekNumber < 0 || weekNumber > 40) return;

    setState(() {
      isLoading = true;
    });

    try {
      final fetchedWeek = await WeekService.getWeekByNumber(weekNumber);
      if (fetchedWeek != null) {
        setState(() {
          currentWeekInfo = fetchedWeek;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading week: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Week ${currentWeekInfo.week}",
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          color: const Color(0xFF764BA2) , 
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
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
                          color: Color(0xFFFEE1DF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            currentWeekInfo.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "Baby Development",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentWeekInfo.baby,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Mom",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentWeekInfo.mom,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Helpful Tips",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentWeekInfo.helpfulTips,
                        style: TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bottom navigation - scrolls with content
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.1),
                            secondaryColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Explore Other Weeks",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Previous Week Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: currentWeekInfo.week > 0
                                      ? () =>
                                            _loadWeek(currentWeekInfo.week - 1)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentWeekInfo.week > 0
                                        ? secondaryColor
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.arrow_back, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        "Week ${currentWeekInfo.week - 1}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(width: 12),

                              // Current Week Indicator
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color.fromARGB(255, 165, 108, 186), secondaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Current",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Week ${currentWeekInfo.week}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 12),

                              // Next Week Button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: currentWeekInfo.week < 40
                                      ? () =>
                                            _loadWeek(currentWeekInfo.week + 1)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentWeekInfo.week < 40
                                        ? secondaryColor
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.arrow_forward, size: 20),
                                      SizedBox(height: 4),
                                      Text(
                                        "Week ${currentWeekInfo.week + 1}",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }
}
