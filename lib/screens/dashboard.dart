import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../APIs/api_service.dart';
import '../user_profile_model.dart';
import '../models/week_info.dart';
import 'pregnancy_nutrition_screen.dart';
import 'pregnancy_exercise_screen.dart';
import 'edit_profile_screen.dart';
import '../services/week_service.dart';
import 'hospital_list_screen.dart';
import 'week_detail_screen.dart';
import 'calender_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  bool _isLoading = true;

  WeekInfo? weekInfo;
  int currentWeek = 0;
  bool isExpanded = false;


  @override
  void initState() {
    super.initState();
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
      Get.snackbar('Error', 'Failed to load profile',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 5) {
      _loadUserProfile();
    }
  }

  // Pregnancy Week Info
 Future<void> _loadWeekInfo() async {
    if (_userProfile == null || _userProfile!.firstDayOfLastPeriod == null) return;

    // Convert the first day of last period to DateTime
    DateTime pregnancyStartDate = DateTime.parse(_userProfile!.firstDayOfLastPeriod!);

    final progress = calculatePregnancyProgress(pregnancyStartDate);
    int currentWeekCalculated = progress['weeksElapsed'];

WeekInfo? fetchedWeek = await WeekService.getWeekByNumber(currentWeekCalculated);    if (fetchedWeek != null) {
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
    }
  }

  Map<String, dynamic> calculatePregnancyProgress(DateTime pregnancyStartDate) {
   DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
   DateTime startDate = DateTime(pregnancyStartDate.year, pregnancyStartDate.month, pregnancyStartDate.day);

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

Widget _buildHomePage() {
    if (_userProfile == null || weekInfo == null) {
      return Center(child: CircularProgressIndicator());
    }

    final progress = calculatePregnancyProgress(DateTime.parse(_userProfile!.firstDayOfLastPeriod!));
    int daysElapsed = progress['daysElapsed'];
    int weeksElapsed = progress['weeksElapsed'];
    int daysInWeek = progress['daysInWeek'];
    int remainingWeeks = progress['remainingWeeks'];
    int remainingDays = progress['remainingDays'];


    return weekInfo == null
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${_userProfile?.fullName ?? 'Nilisha'}!',
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
                                child: Icon(Icons.broken_image,
                                    size: 80, color: Colors.grey),
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
                        Text("Baby Development",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
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
                        Text("Mom",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
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
                        Text("Helpful Tips",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              Text(weekInfo!.helpfulTips, style: TextStyle(fontSize: 16)),
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
                          Text(
                              "Before birth: $remainingWeeks weeks $remainingDays days"),
                          Text("Day $daysElapsed (${weeksElapsed}w + ${daysInWeek}d)"),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),
              ],
            ),
          );
  }

  // Hospital Page Content
  Widget _buildHospitalPage() => HospitalListScreen();

   // Exercise Page Content
  Widget _buildExercisePage() => PregnancyExerciseScreen();

    // Health Page Content shows Pregnancy Nutrition
  Widget _buildHealthPage() => PregnancyNutritionScreen();

 // Profile Page Content
  Widget _buildProfilePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
        ),
      ),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red),
                      SizedBox(height: 20),
                      Text('Failed to load profile'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Color(0xFF667EEA).withOpacity(0.1),
                            backgroundImage: _userProfile!.photoUrl != null
                                ? NetworkImage(_userProfile!.photoUrl!)
                                : null,
                            child: _userProfile!.photoUrl == null
                                ? Icon(Icons.person, size: 60, color: Color(0xFF667EEA))
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        _userProfile!.fullName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, size: 16, color: Color(0xFF718096)),
                          SizedBox(width: 5),
                          Text(
                            _userProfile!.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Profile Details Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF667EEA),
                              ),
                            ),
                            Divider(height: 30),
                            _buildProfileItem(
                              icon: Icons.location_on,
                              label: 'Address',
                              value: _userProfile!.address ?? 'Not provided',
                            ),
                            SizedBox(height: 15),
                            _buildProfileItem(
                              icon: Icons.calendar_today,
                              label: 'First Day of Last Period',
                              value:
                                  _userProfile!.firstDayOfLastPeriod ?? 'Not provided',
                            ),
                            SizedBox(height: 15),
                            _buildProfileItem(
                              icon: Icons.baby_changing_station,
                              label: 'Due Date',
                              value: _userProfile!.dueDate ?? 'Not calculated',
                            ),
                            SizedBox(height: 15),
                            _buildProfileItem(
                              icon: Icons.access_time,
                              label: 'Member Since',
                              value: _formatDate(_userProfile!.createdAt),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // Edit & Logout Buttons
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Edit Profile Button 
                            InkWell(
                              onTap: () async {
                                if (_userProfile != null) {
                                  final result = await Get.to(() =>
                                      EditProfileScreen(userProfile: _userProfile!));
                                  if (result == true) {
                                    await _loadUserProfile();
                                    await _loadWeekInfo();
                                    setState(() {}); 
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Color(0xFF667EEA).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text('Edit Profile',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            // Logout
                            InkWell(
                              onTap: _showLogoutDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[400]!, width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout,
                                        color: Colors.red[400], size: 22),
                                    SizedBox(width: 10),
                                    Text('Logout',
                                        style: TextStyle(
                                            color: Colors.red[400],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  //Logout Dialog
  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(8)),
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
        content: Text('Are you sure you want to logout?',
            style: TextStyle(fontSize: 16, color: Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667EEA).withOpacity(0.3),
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
              child: Text('Logout',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _buildProfileItem(
      {required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Color(0xFF667EEA)),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _buildHomePage(),
      _buildHospitalPage(),
      _buildHealthPage(),
      _buildExercisePage(),
      _buildProfilePage(),
    ];

    bool showAppBar = _selectedIndex == 0 || _selectedIndex == 5;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text('MaMata - Embracing Motherhood'),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
              ),
              foregroundColor: Colors.white,
              elevation: 0,
             actions: [
                if (_selectedIndex == 0) // show only on Home page
                    IconButton(
                       icon: Icon(Icons.calendar_today),
                       onPressed: () {
                // Navigate to the calendar page
                Get.to(() => MyCalendarPage());
              },
            ),
        ],

            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'Hospital'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercise'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF667EEA),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
