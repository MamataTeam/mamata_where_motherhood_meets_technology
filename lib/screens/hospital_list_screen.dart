import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import '../models/hospital.dart';
import '../widgets/hospital_card.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key});

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen>
    with SingleTickerProviderStateMixin {
  // Purple/Violet Professional Theme
  static const primaryColor = Color(0xFF667EEA);
  static const secondaryColor = Color(0xFF764BA2);
  static const errorColor = Color(0xFFE74C3C);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardColor = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  Future<List<Hospital>>? hospitalList;
  Position? userPosition;
  bool isLoadingLocation = true;
  String? locationError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoadingLocation = true;
      locationError = null;
      userPosition = null;
      hospitalList = null;
    });

    await _getUserLocation();
    setState(() {
      hospitalList = _loadHospitals();
    });
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError = 'Location services are disabled.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError = 'Location permission denied.';
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError = 'Location permissions are permanently denied.';
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      userPosition = position;
    } catch (e) {
      locationError = 'Error getting location: $e';
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<List<Hospital>> _loadHospitals() async {
    final String jsonData =
        await rootBundle.loadString('assets/hospitals.json');
    final List data = json.decode(jsonData);
    List<Hospital> hospitals =
        data.map((json) => Hospital.fromJson(json)).toList();

    if (userPosition != null) {
      for (var hospital in hospitals) {
        hospital.distance = Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          hospital.latitude,
          hospital.longitude,
        );
      }

      // Filter hospitals within 5 KM radius (5000 meters)
      hospitals = hospitals.where((hospital) {
        return hospital.distance != null && hospital.distance! <= 5000;
      }).toList();

      // Sort by distance
      hospitals.sort((a, b) {
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
    }

    return hospitals;
  }

  Widget _buildLocationBanner() {
    final String title;
    final String subtitle;
    final Color iconColor;

    if (isLoadingLocation) {
      title = 'Locating You';
      subtitle = 'Finding nearby hospitals...';
      iconColor = primaryColor;
    } else if (locationError != null) {
      title = 'Location Unavailable';
      subtitle = locationError!;
      iconColor = errorColor;
    } else if (userPosition != null) {
      title = 'Location Found';
      subtitle = 'Filtering results within 5 KM radius';
      iconColor = primaryColor;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            primaryColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withOpacity(0.15),
                      iconColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoadingLocation
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : Icon(
                        locationError != null
                            ? Icons.location_off_outlined
                            : Icons.location_on,
                        color: iconColor,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (locationError != null && !isLoadingLocation)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [errorColor, errorColor.withOpacity(0.85)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: errorColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: initializeData,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool isError = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isError
                  ? null
                  : LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        secondaryColor.withOpacity(0.1),
                      ],
                    ),
              color: isError ? errorColor.withOpacity(0.1) : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 56,
              color: iconColor ?? primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.03),
              backgroundColor,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                ),
              ),
              foregroundColor: Colors.white,
              title: const Text(
                'Nearby Hospitals',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.my_location_outlined, size: 24),
                  onPressed: initializeData,
                  tooltip: 'Refresh Location and List',
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLocationBanner(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: FutureBuilder<List<Hospital>>(
                future: hospitalList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.refresh,
                        title: 'Loading hospitals...',
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.error_outline,
                        title: 'Error loading data',
                        subtitle:
                            'An unexpected error occurred. Please try again.',
                        iconColor: errorColor.withOpacity(0.7),
                        isError: true,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.local_hospital_outlined,
                        title: 'No hospitals found',
                      ),
                    );
                  }

                  final hospitals = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: HospitalCard(hospital: hospitals[index]),
                        );
                      },
                      childCount: hospitals.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
