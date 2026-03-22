import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Call this once from main.dart or your splash screen
  static Future<void> requestAllPermissions(BuildContext context) async {
    await _requestLocation(context);
    await _requestNotification(context);
    await _requestCalendar(context);
  }

  static Future<void> _requestLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSettingsDialog(
        context,
        title: 'Location Required',
        message:
            'Location services are disabled. Please enable GPS to find nearby hospitals.',
        onSettings: () => Geolocator.openLocationSettings(),
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      _showSettingsDialog(
        context,
        title: 'Location Permission Denied',
        message:
            'Location permission is permanently denied. Please enable it in Settings to find nearby hospitals.',
        onSettings: () => Geolocator.openAppSettings(),
      );
    }
  }

  static Future<void> _requestNotification(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog(
        context,
        title: 'Notification Permission Denied',
        message:
            'Notifications are permanently denied. Enable them in Settings to receive appointment reminders.',
        onSettings: () => openAppSettings(),
      );
    }
  }

  static Future<void> _requestCalendar(BuildContext context) async {
  PermissionStatus status;

  // calendarFullAccess exists in permission_handler 11+
  // Fall back to Permission.calendar for older versions
  try {
    final statuses = await [
      Permission.calendar,
    ].request();
    status = statuses[Permission.calendar] ?? PermissionStatus.denied;
  } catch (_) {
    status = await Permission.calendar.request();
  }

  if (status.isPermanentlyDenied) {
    _showSettingsDialog(
      context,
      title: 'Calendar Permission Denied',
      message:
          'Calendar access is permanently denied. Enable it in Settings to sync your appointments.',
      onSettings: () => openAppSettings(),
    );
  }
}
  static void _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onSettings,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF764BA2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
