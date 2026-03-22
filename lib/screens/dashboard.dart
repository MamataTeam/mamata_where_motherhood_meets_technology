import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../APIs/api_service.dart';
import '../user_profile_model.dart';
import '../models/week_info.dart';
import 'pregnancy_nutrition_screen.dart';
import 'pregnancy_exercise_screen.dart';
import 'edit_profile_screen.dart';
import '../services/week_service.dart';
import '../services/week_image_service.dart';
import '../services/baby_week_service.dart';
import '../services/permission_service.dart';
import '../models/baby_week.dart';
import 'hospital_list_screen.dart';
import 'week_detail_screen.dart';
import 'calender_page.dart';
import 'chatbot_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String appBarTitle = '';

  WeekInfo? weekInfo;
  int currentWeek = 0;
  bool isExpanded = false;
  String? weekImageUrl;
  BabyWeek? babyWeekData;

  // Gradient colors (rest of dashboard unchanged)
  static const primaryColor = Color(0xFF667EEA);
  static const secondaryColor = Color(0xFF764BA2);

  // ── Clay Palette (chatbot banner only) ────────────────────────
  static const clayPrimary = Color(0xFF924629); // Terracotta
  static const claySurface = Color(0xFFF1EEE5); // Dusty Rose / Peach
  static const clayBg = Color(0xFFFCF9F0); // Soft Cream
  // ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Request permissions after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAllPermissions(context);
    });
    _loadUserProfile().then((_) => _loadWeekInfo());
  }

  //User Profile
  Future<void> _loadUserProfile() async {
    try {
      final profile = await ApiService.fetchUserProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load profile',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) {
      _loadUserProfile();
    }
  }

  // Load week-specific image
  Future<void> _loadWeekImage() async {
    if (currentWeek < 0 || currentWeek > 40) return;

    try {
      final imageUrl = await WeekImageService.getImageUrlForWeek(currentWeek);
      final babyWeek = await BabyWeekService.getBabyWeekByNumber(currentWeek);
      setState(() {
        weekImageUrl = imageUrl;
        babyWeekData = babyWeek;
      });
    } catch (e) {
      print('Error loading week image: $e');
    }
  }

  // Pregnancy Week Info
  Future<void> _loadWeekInfo() async {
    if (_userProfile == null || _userProfile!.firstDayOfLastPeriod == null)
      return;

    DateTime pregnancyStartDate = DateTime.parse(
      _userProfile!.firstDayOfLastPeriod!,
    );
    final progress = calculatePregnancyProgress(pregnancyStartDate);
    int currentWeekCalculated = progress['weeksElapsed'];

    WeekInfo? fetchedWeek = await WeekService.getWeekByNumber(
      currentWeekCalculated,
    );

    if (fetchedWeek != null) {
      setState(() {
        weekInfo = WeekInfo(
          week: fetchedWeek.week,
          baby: fetchedWeek.baby,
          mom: fetchedWeek.mom,
          helpfulTips: fetchedWeek.helpfulTips,
          imageUrl: fetchedWeek.imageUrl,
        );
        currentWeek = currentWeekCalculated;
      });

      await _loadWeekImage();
    }
  }

  Map<String, dynamic> calculatePregnancyProgress(DateTime pregnancyStartDate) {
    DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    DateTime startDate = DateTime(
      pregnancyStartDate.year,
      pregnancyStartDate.month,
      pregnancyStartDate.day,
    );

    Duration diff = today.difference(startDate);

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

  String getTrimester(int week) {
    if (week <= 13) return "Trimester 1";
    if (week <= 27) return "Trimester 2";
    return "Trimester 3";
  }

  // Load all baby weeks for gallery
  Future<List<BabyWeek>> _loadAllBabyWeeks() async {
    List<BabyWeek> allWeeks = [];
    for (int i = 0; i <= 40; i++) {
      try {
        final week = await BabyWeekService.getBabyWeekByNumber(i);
        if (week != null) {
          allWeeks.add(week);
        } else {
          allWeeks.add(
            BabyWeek(
              week: i,
              comparison: 'Unknown',
              weightGrams: 0,
              heightCm: 0,
              heartRateBpm: 'N/A',
              hcgRange: 'N/A',
              imageUrl: '',
            ),
          );
        }
      } catch (e) {
        print('Error loading week $i: $e');
        allWeeks.add(
          BabyWeek(
            week: i,
            comparison: 'Unknown',
            weightGrams: 0,
            heightCm: 0,
            heartRateBpm: 'N/A',
            hcgRange: 'N/A',
            imageUrl: '',
          ),
        );
      }
    }
    return allWeeks;
  }

  Widget _buildHomePage() {
    if (_userProfile == null || weekInfo == null) {
      return Center(child: CircularProgressIndicator());
    }

    final progress = calculatePregnancyProgress(
      DateTime.parse(_userProfile!.firstDayOfLastPeriod!),
    );
    int daysElapsed = progress['daysElapsed'];
    int weeksElapsed = progress['weeksElapsed'];
    int daysInWeek = progress['daysInWeek'];
    int remainingWeeks = progress['remainingWeeks'];
    int remainingDays = progress['remainingDays'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'Hi, ${_userProfile?.fullName}!',
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
                            builder: (context) =>
                                WeekDetailScreen(weekInfo: weekInfo!),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10),

                if (isExpanded) ...[
                  SizedBox(height: 25),
                  Text(
                    "Baby Development",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
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
                  Text(
                    "Mom",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
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
                  Text(
                    "Helpful Tips",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      weekInfo!.helpfulTips,
                      style: TextStyle(fontSize: 16),
                    ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${weekInfo!.week} weeks",
                      style: const TextStyle(
                        color: Color(0xFF5B2C6F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      getTrimester(weekInfo!.week),
                      style: const TextStyle(
                        color: Color(0xFF0A3D62),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                LinearProgressIndicator(
                  value: weekInfo!.week / 40,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF764BA2)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(5),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Before birth: $remainingWeeks weeks $remainingDays days",
                    ),
                    Text(
                      "Day $daysElapsed (${weeksElapsed}w + ${daysInWeek}d)",
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 25),

          // ─────────────────────────────────────
          // CHATBOT BANNER ← CLAY PALETTE APPLIED
          // ─────────────────────────────────────
          _buildChatbotBanner(),

          SizedBox(height: 25),

          // THIS WEEK SECTION
          if (weekImageUrl != null && babyWeekData != null) ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showPregnancyWeeksGallery();
                    },
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: Color(0xFFEFD9F2), // French Lilac
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEFD9F2).withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              top: 70,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Color(0xFFEFD9F2).withOpacity(0.3),
                                  BlendMode.multiply,
                                ),
                                child: Image.network(
                                  weekImageUrl!,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFFEFD9F2),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "My bump",
                                    style: TextStyle(
                                      color: Color(0xFF0E4C87), // Torea Bay
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Watch the tummy grow",
                                    style: TextStyle(
                                      color: Color(0xFF0E4C87).withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showBabyDevelopmentGallery();
                    },
                    child: Container(
                      height: 240,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 218, 175, 123),
                            Color(0xFFFFE8CC),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.15),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              top: 70,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  Color.fromRGBO(
                                    255,
                                    232,
                                    204,
                                    1,
                                  ).withOpacity(0.3),
                                  BlendMode.multiply,
                                ),
                                child: Image.network(
                                  babyWeekData!.imageUrl,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFFFFE8CC),
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              right: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Baby size:",
                                    style: TextStyle(
                                      color: Color(0xFF78350F),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "a ${babyWeekData!.comparison}",
                                    style: TextStyle(
                                      color: Color(0xFF78350F).withOpacity(0.6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    title: "Nutrition",
                    subtitle: "Stay healthy",
                    color: Colors.purple.withOpacity(0.15),
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: Color(0xFF764BA2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PregnancyNutritionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildDashboardCard(
                    title: "Exercise",
                    subtitle: "Safe workouts",
                    color: Colors.orange.withOpacity(0.10),
                    icon: Icons.fitness_center_rounded,
                    iconColor: Color(0xFF7B2D3E),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PregnancyExerciseScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
          ],
        ],
      ),
    );
  }

  // ── CHATBOT BANNER — Clay Palette ─────────────────────────────
  Widget _buildChatbotBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EDE6), // light cream
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF924629).withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Heart with baby icon in soft circle
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE8C9B8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                color: Color(0xFF924629),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pregnancy Assistant',
                    style: TextStyle(
                      color: Color(0xFF3B1A0E),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ask me anything about your pregnancy',
                    style: TextStyle(color: Color(0xFF6B3A28), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF924629),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  // ──────────────────────────────────────────────────────────────

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 36, color: iconColor),
          ],
        ),
      ),
    );
  }

  void _showPregnancyWeeksGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pregnancy Weeks",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: WeekImageService.loadWeekImages(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        return PageView.builder(
                          controller: PageController(
                            initialPage: currentWeek,
                            viewportFraction: 0.85,
                          ),
                          itemCount: 41,
                          itemBuilder: (context, index) {
                            final weekImage = snapshot.data![index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Week $index",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0E4C87),
                                          ),
                                        ),
                                        if (index == currentWeek) ...[
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF0E4C87),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Current",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        weekImage.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 80,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBabyDevelopmentGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Baby Development",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<BabyWeek>>(
                      future: _loadAllBabyWeeks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text("No data available"));
                        }

                        return PageView.builder(
                          controller: PageController(
                            initialPage: currentWeek,
                            viewportFraction: 0.85,
                          ),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final babyWeek = snapshot.data![index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Week ${babyWeek.week}",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF78350F),
                                            ),
                                          ),
                                          if (babyWeek.week == currentWeek) ...[
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF78350F),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                "Current",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.network(
                                              babyWeek.imageUrl,
                                              height: 200,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      height: 200,
                                                      child: Center(
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
                                          SizedBox(height: 20),
                                          Text(
                                            "My baby is like",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "a ${babyWeek.comparison}",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 20),
                                          _buildInfoRow(
                                            Icons.monitor_weight_outlined,
                                            "Weight",
                                            "${babyWeek.weightGrams} g",
                                          ),
                                          SizedBox(height: 12),
                                          _buildInfoRow(
                                            Icons.height,
                                            "Height",
                                            "${babyWeek.heightCm} cm",
                                          ),
                                          SizedBox(height: 12),
                                          _buildInfoRow(
                                            Icons.favorite,
                                            "Heart rate",
                                            babyWeek.heartRateBpm,
                                          ),
                                          SizedBox(height: 12),
                                          _buildInfoRow(
                                            Icons.science_outlined,
                                            "hCG norms",
                                            babyWeek.hcgRange,
                                          ),
                                          SizedBox(height: 20),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarPage() {
    DateTime? dueDate;
    if (_userProfile?.dueDate != null) {
      dueDate = DateTime.tryParse(_userProfile!.dueDate!);
    }
    return MyCalendarPage(dueDate: dueDate, userId: _userProfile?.email);
  }

  Widget _buildHospitalPage() => HospitalListScreen();

  Widget _buildProfilePage() {
    return Container(
      color: const Color(0xFFF9F0FB),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load profile'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B4F9E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFFE0C4EA),
                    backgroundImage: _userProfile!.photoUrl != null
                        ? NetworkImage(_userProfile!.photoUrl!)
                        : null,
                    child: _userProfile!.photoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 44,
                            color: Color(0xFF7B4F9E),
                          )
                        : null,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    _userProfile!.fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C1A3A),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _userProfile!.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E7A8E),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Details — no card, just rows
                  _buildProfileRow(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: _userProfile!.address ?? 'Not provided',
                  ),
                  _buildProfileRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'First Day of Last Period',
                    value: _userProfile!.firstDayOfLastPeriod ?? 'Not provided',
                  ),
                  _buildProfileRow(
                    icon: Icons.child_care_rounded,
                    label: 'Due Date',
                    value: _userProfile!.dueDate ?? 'Not calculated',
                  ),
                  _buildProfileRow(
                    icon: Icons.access_time_rounded,
                    label: 'Member Since',
                    value: _formatDate(_userProfile!.createdAt),
                  ),

                  const SizedBox(height: 40),

                  // Edit Profile
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_userProfile != null) {
                          final result = await Get.to(
                            () => EditProfileScreen(userProfile: _userProfile!),
                          );
                          if (result == true) {
                            await _loadUserProfile();
                            await _loadWeekInfo();
                            setState(() {});
                          }
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B4F9E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 17,
                        color: Colors.red[400],
                      ),
                      label: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red[300]!, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16, color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: secondaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                Get.back();
                await ApiService.deleteToken();
                Get.offAllNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildProfileRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7B4F9E)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E7A8E),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1A3A),
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: const Color(0xFFEFD9F2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF7B4F9E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF7B4F9E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9E7A8E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C1A3A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF78350F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Color(0xFF78350F)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomePage(),
      _buildCalendarPage(),
      _buildHospitalPage(),
      _buildProfilePage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital),
            label: 'Hospital',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF764BA2),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
