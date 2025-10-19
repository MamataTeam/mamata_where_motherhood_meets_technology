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
  // Purple/Violet Professional Theme
  static const primaryColor = Color(0xFF667EEA); // Purple
  static const secondaryColor = Color(0xFF764BA2); // Violet
  static const errorColor = Color(0xFFE74C3C); // Hospital marker

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
      final hospitalLatLng =
          LatLng(widget.hospital.latitude, widget.hospital.longitude);

      final url =
          'http://router.project-osrm.org/route/v1/driving/${userLatLng.longitude},${userLatLng.latitude};${hospitalLatLng.longitude},${hospitalLatLng.latitude}?overview=full&geometries=geojson';
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final coords =
            json.decode(res.body)['routes'][0]['geometry']['coordinates'];
        routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
      }

      if (mounted) {
        setState(() {
          userLocation = userLatLng;
          isLoading = false;
        });

        if (routePoints.isNotEmpty) _fitBounds();
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _fitBounds() {
    final points = [
      userLocation!,
      LatLng(widget.hospital.latitude, widget.hospital.longitude),
      ...routePoints
    ];
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);

    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b)),
        LatLng(lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b)),
      ),
      padding: const EdgeInsets.all(50),
    ));
  }

  void _zoom(LatLng point) => _mapController.move(point, 16);

  Widget _buildMapButton(IconData icon, VoidCallback onTap, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        iconSize: 24,
        padding: const EdgeInsets.all(12),
      ),
    );
  }

  Marker _buildMarker({
    required LatLng point,
    required IconData icon,
    required Color color,
    bool hasBorder = false,
  }) {
    return Marker(
      point: point,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _zoom(point),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border:
                hasBorder ? Border.all(color: Colors.white, width: 3) : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)
            ],
          ),
          child: Icon(icon, color: Colors.white, size: hasBorder ? 20 : 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hospitalLatLng =
        LatLng(widget.hospital.latitude, widget.hospital.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hospital.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
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
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: hospitalLatLng,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  _buildMarker(
                    point: hospitalLatLng,
                    icon: Icons.local_hospital,
                    color: errorColor,
                  ),
                  if (userLocation != null)
                    _buildMarker(
                      point: userLocation!,
                      icon: Icons.person,
                      color: primaryColor,
                      hasBorder: true,
                    ),
                ],
              ),
            ],
          ),
          if (isLoading)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Loading route...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (routePoints.isNotEmpty)
                  _buildMapButton(Icons.route, _fitBounds, primaryColor),
                if (userLocation != null)
                  _buildMapButton(
                    Icons.my_location,
                    () => _zoom(userLocation!),
                    primaryColor,
                  ),
                _buildMapButton(
                  Icons.local_hospital,
                  () => _zoom(hospitalLatLng),
                  errorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
