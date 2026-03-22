import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/hospital.dart';

class HospitalMapScreen extends StatefulWidget {
  final Hospital hospital;
  const HospitalMapScreen({super.key, required this.hospital});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  // ── Palette — matches calendar screen ────────────────────────────────────
  static const _purple = Color(0xFF764BA2);
  static const _purpleMid = Color(0xFF9B6EC4);
  static const _purpleSoft = Color(0xFFF3EDF9);
  static const _gold = Color(0xFFC9933A);
  static const _crimson = Color(0xFFB83232);
  static const _crimsonSoft = Color(0xFFFAECEC);
  static const _green = Color(0xFF27AE60);
  static const _greenSoft = Color(0xFFE8F8EE);
  static const _ink = Color(0xFF2D1B4E);
  static const _ghost = Color(0xFFBEB3CC);
  static const _white = Color(0xFFFFFFFF);
  static const _border = Color(0xFFF0E8F5);

  LatLng? userLocation;
  List<LatLng> routePoints = [];
  final _mapController = MapController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition();
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      final hospitalLatLng = LatLng(
        widget.hospital.latitude,
        widget.hospital.longitude,
      );
      final url =
          'http://router.project-osrm.org/route/v1/driving/'
          '${userLatLng.longitude},${userLatLng.latitude};'
          '${hospitalLatLng.longitude},${hospitalLatLng.latitude}'
          '?overview=full&geometries=geojson';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final coords = json.decode(
          res.body,
        )['routes'][0]['geometry']['coordinates'];
        routePoints = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
      }
      if (mounted) {
        setState(() {
          userLocation = userLatLng;
          isLoading = false;
        });
        if (routePoints.isNotEmpty) _fitBounds();
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _fitBounds() {
    final points = [
      userLocation!,
      LatLng(widget.hospital.latitude, widget.hospital.longitude),
      ...routePoints,
    ];
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          ),
          LatLng(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(50, 50, 50, 220),
      ),
    );
  }

  void _zoom(LatLng point) => _mapController.move(point, 16);

  Widget _buildMapBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 19),
        onPressed: onTap,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      ),
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required IconData icon,
    required Color bgColor,
    bool isUser = false,
  }) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _zoom(point),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: _white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: _white, size: isUser ? 15 : 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalLatLng = LatLng(
      widget.hospital.latitude,
      widget.hospital.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF7B4F9E),
        surfaceTintColor: const Color(0xFF7B4F9E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hospital.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.hospital.address,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: hospitalLatLng, initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.mamata_app',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF7B4F9E).withOpacity(0.85),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  _buildMarker(
                    point: hospitalLatLng,
                    icon: Icons.local_hospital_rounded,
                    bgColor: _crimson,
                  ),
                  if (userLocation != null)
                    _buildMarker(
                      point: userLocation!,
                      icon: Icons.person_rounded,
                      bgColor: const Color(0xFF7B4F9E),
                      isUser: true,
                    ),
                ],
              ),
            ],
          ),

          // ── Loading pill ───────────────────────────────────────────────
          if (isLoading)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(_purple),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'Loading route…',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Map control buttons ────────────────────────────────────────
          Positioned(
            top: 14,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (routePoints.isNotEmpty)
                  _buildMapBtn(
                    icon: Icons.fit_screen_rounded,
                    onTap: _fitBounds,
                    color: _purple,
                  ),
                if (userLocation != null)
                  _buildMapBtn(
                    icon: Icons.my_location_rounded,
                    onTap: () => _zoom(userLocation!),
                    color: _purple,
                  ),
                _buildMapBtn(
                  icon: Icons.local_hospital_rounded,
                  onTap: () => _zoom(hospitalLatLng),
                  color: _crimson,
                ),
              ],
            ),
          ),

          // ── Bottom info card ───────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Solid purple header strip
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B4F9E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.hospital.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.hospital.distance != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.hospital.distance! < 1000
                                      ? '${widget.hospital.distance!.toStringAsFixed(0)} m away'
                                      : '${(widget.hospital.distance! / 1000).toStringAsFixed(1)} km away',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Emergency badge row (white section)
                  if (widget.hospital.emergency)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _greenSoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _green.withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.emergency_rounded,
                                  size: 11,
                                  color: _green,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '24h Emergency Available',
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}