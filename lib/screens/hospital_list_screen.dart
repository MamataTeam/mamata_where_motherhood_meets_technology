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
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF764BA2);
  static const _purpleSoft = Color(0xFFF3EDF9);
  static const _green = Color(0xFF27AE60);
  static const _crimson = Color(0xFFB83232);
  static const _crimsonSoft = Color(0xFFFAECEC);
  static const _ink = Color(0xFF2D1B4E);
  static const _sub = Color(0xFF7B6B8D);
  static const _ghost = Color(0xFFBEB3CC);

  Future<List<Hospital>>? _hospitalList;
  Position? _userPosition;
  bool _loadingLocation = true;
  String? _locationError;
  bool _permanentlyDenied = false; // ← new
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _initData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Data init ─────────────────────────────────────────────────────────────
  Future<void> _initData() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
      _userPosition = null;
      _hospitalList = null;
      _permanentlyDenied = false;
    });
    await _getLocation();
    setState(() => _hospitalList = _loadHospitals());
  }

  Future<void> _getLocation() async {
    try {
      // 1. Check if GPS is switched on
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError =
            'Location services are disabled. Please turn on GPS.';
        return;
      }

      // 2. Check / request permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _locationError = 'Location permission denied.';
          return;
        }
      }

      // 3. Permanently denied → send user to app Settings
      if (perm == LocationPermission.deniedForever) {
        _locationError =
            'Location permanently denied. Tap "Open Settings" to enable it.';
        _permanentlyDenied = true;
        return;
      }

      // 4. All good — get position
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      _locationError = 'Could not get location. Please try again.';
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<List<Hospital>> _loadHospitals() async {
    final raw = await rootBundle.loadString('assets/hospitals.json');
    final data = json.decode(raw) as List;
    List<Hospital> list = data.map((j) => Hospital.fromJson(j)).toList();
    if (_userPosition != null) {
      for (var h in list) {
        h.distance = Geolocator.distanceBetween(
          _userPosition!.latitude,
          _userPosition!.longitude,
          h.latitude,
          h.longitude,
        );
      }
      list = list
          .where((h) => h.distance != null && h.distance! <= 5000)
          .toList();
      list.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    }
    return list;
  }

  // ── Location banner ───────────────────────────────────────────────────────
  Widget _buildLocationBanner() {
    if (!_loadingLocation && _locationError == null && _userPosition == null) {
      return const SizedBox.shrink();
    }

    final isError = _locationError != null && !_loadingLocation;
    final isSuccess = !_loadingLocation && _userPosition != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: isError ? _crimsonSoft : _purpleSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? _crimson.withOpacity(0.2)
              : _purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Icon bubble ──────────────────────────────────────────────
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isError
                  ? _crimson.withOpacity(0.1)
                  : _purple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _loadingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_purple),
                      ),
                    )
                  : Icon(
                      isError
                          ? Icons.location_off_outlined
                          : Icons.location_on_rounded,
                      size: 17,
                      color: isError ? _crimson : _purple,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Status text ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadingLocation
                      ? 'Finding your location…'
                      : isError
                          ? 'Location unavailable'
                          : 'Location found',
                  style: TextStyle(
                    color: isError ? _crimson : _ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _loadingLocation
                      ? 'Searching for nearby hospitals'
                      : isError
                          ? _locationError!
                          : 'Showing results within 5 km',
                  style: TextStyle(
                    color: isError ? _crimson.withOpacity(0.65) : _sub,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Action badge / button ────────────────────────────────────
          if (isSuccess)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green, width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 11, color: _green),
                  SizedBox(width: 4),
                  Text(
                    'Active',
                    style: TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

          if (isError)
            GestureDetector(
              // Permanently denied → open app Settings
              // Otherwise → retry the location flow
              onTap: _permanentlyDenied
                  ? () => Geolocator.openAppSettings()
                  : _initData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _permanentlyDenied ? 'Open Settings' : 'Retry',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty / error state ───────────────────────────────────────────────────
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isError = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isError ? _crimsonSoft : _purpleSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 44,
              color: isError
                  ? _crimson.withOpacity(0.7)
                  : _purple.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                subtitle,
                style: const TextStyle(color: _ghost, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF9F0FB),
              Color(0xFFEFD9F2),
              Color(0xFFE0C4EA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ───────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              elevation: 0,
              toolbarHeight: 56,
              expandedHeight: 56,
              backgroundColor: const Color(0xFF7B4F9E),
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: const Text(
                'Nearby Hospitals',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _initData,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),

            // ── Location banner ──────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildLocationBanner(),
              ),
            ),

            // ── Hospital list ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 36),
              sliver: FutureBuilder<List<Hospital>>(
                future: _hospitalList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Finding hospitals…',
                        subtitle: 'Searching near your location.',
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: 'Something went wrong',
                        subtitle: 'Please try again.',
                        isError: true,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(
                        icon: Icons.local_hospital_outlined,
                        title: 'No hospitals nearby',
                        subtitle: 'No hospitals found within 5 km.',
                      ),
                    );
                  }

                  final hospitals = snapshot.data!;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return FadeTransition(
                            opacity: _fadeAnim,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20, 22, 20, 16,
                                  ),
                                  child: Text(
                                    '${hospitals.length} hospitals found',
                                    style: const TextStyle(
                                      color: _ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: HospitalCard(hospital: hospitals[0]),
                                ),
                              ],
                            ),
                          );
                        }
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: HospitalCard(hospital: hospitals[index]),
                          ),
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