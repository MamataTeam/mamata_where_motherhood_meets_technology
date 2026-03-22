import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;
import 'package:table_calendar/table_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';

class MyCalendarPage extends StatefulWidget {
  final DateTime? dueDate;
  final String? userId;

  const MyCalendarPage({Key? key, this.dueDate, this.userId}) : super(key: key);

  @override
  _MyCalendarPageState createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<Map<String, dynamic>>> events = {};
  Map<DateTime, List<Map<String, dynamic>>> notes = {};
  final _firestore = FirebaseFirestore.instance;
  final _secureStorage = const FlutterSecureStorage();
  static const String _userIdKey = 'userId';
  late String _userId;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  String? _deviceCalendarId;

  final Color themeColor2 = const Color(0xFF764BA2);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notesSub;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    } catch (_) {}

    _initNotifications();
    _initDeviceCalendar();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveUserIdAndListen();
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _notesSub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    if (kIsWeb) return;

    try {
      // Request notification permission for Android 13+
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      await _fln.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );

      // Create notification channel with sound
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'event_reminders_v3',
        'Event Reminders',
        description: 'Notifications for calendar events',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('reminder'),
        enableVibration: true,
        enableLights: true,
      );

      final plugin = _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await plugin?.createNotificationChannel(channel);

      debugPrint('Notification system initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  Future<void> _initDeviceCalendar() async {
    if (kIsWeb) return;

    try {
      // Request calendar permissions
      var permissionsGranted = await _deviceCalendar.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendar.requestPermissions();
      }

      if (permissionsGranted.isSuccess && permissionsGranted.data!) {
        // Get available calendars
        final calendarsResult = await _deviceCalendar.retrieveCalendars();
        if (calendarsResult.isSuccess && calendarsResult.data != null) {
          // Find or create a calendar for our app
          final calendars = calendarsResult.data!;
          final appCalendar = calendars.firstWhere(
            (cal) => cal.name == 'My Calendar App',
            orElse: () => calendars.first,
          );
          _deviceCalendarId = appCalendar.id;
          debugPrint('Device calendar initialized: ${appCalendar.name}');
        }
      } else {
        debugPrint('Calendar permissions not granted');
      }
    } catch (e) {
      debugPrint('Error initializing device calendar: $e');
    }
  }

  Future<void> _scheduleNotificationForEvent({
    required String id,
    required String title,
    required DateTime scheduledDateTime,
  }) async {
    if (kIsWeb || scheduledDateTime.isBefore(DateTime.now())) {
      return;
    }

    try {
      final tz.TZDateTime tzDate = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );

      final androidDetails = AndroidNotificationDetails(
        'event_reminders_v3',
        'Event Reminders',
        channelDescription: 'Notifications for calendar events',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('reminder'),
        enableVibration: true,
        enableLights: true,
        color: themeColor2,
      );

      const iosDetails = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        sound: 'default',
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final int notifId = id.hashCode & 0x7fffffff;

      await _fln.zonedSchedule(
        notifId,
        'Event Reminder',
        title,
        tzDate,
        details,
        payload: id,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        'Notification scheduled for: $title at $scheduledDateTime (ID: $notifId)',
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelNotificationForEvent(String id) async {
    if (kIsWeb) return;
    try {
      final int notifId = id.hashCode & 0x7fffffff;
      await _fln.cancel(notifId);
      debugPrint('Notification cancelled for event: $id');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<String?> _addToDeviceCalendar({
    required String title,
    required DateTime start,
    String? description,
    String? location,
  }) async {
    if (kIsWeb || _deviceCalendarId == null) return null;

    try {
      final event = Event(
        _deviceCalendarId,
        title: title,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(start.add(const Duration(hours: 1)), tz.local),
        description: description,
        location: location,
      );

      final result = await _deviceCalendar.createOrUpdateEvent(event);
      if (result?.isSuccess == true && result?.data != null) {
        debugPrint('Added to device calendar: $title (ID: ${result!.data})');
        return result.data;
      }
    } catch (e) {
      debugPrint('Error adding to device calendar: $e');
    }
    return null;
  }

  Future<void> _removeFromDeviceCalendar(String? deviceEventId) async {
    if (kIsWeb || deviceEventId == null || _deviceCalendarId == null) return;

    try {
      final result = await _deviceCalendar.deleteEvent(
        _deviceCalendarId,
        deviceEventId,
      );
      if (result?.isSuccess == true) {
        debugPrint('Removed from device calendar: $deviceEventId');
      }
    } catch (e) {
      debugPrint('Error removing from device calendar: $e');
    }
  }

  Future<void> _resolveUserIdAndListen() async {
    final passed = widget.userId;
    if (passed != null && passed.isNotEmpty) {
      _userId = passed;
    } else {
      final stored = await _secureStorage.read(key: _userIdKey);
      _userId = (stored != null && stored.isNotEmpty) ? stored : 'unknown_user';
    }
    _startEventsListener();
    _startNotesListener();
  }

  void _startEventsListener() {
    final coll = _firestore
        .collection('users')
        .doc(_userId)
        .collection('events');
    _eventsSub = coll.snapshots().listen((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> loaded = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final title = (data['title'] ?? 'Event').toString();
        final timestampVal = data['timestamp'];
        DateTime dt;
        if (timestampVal is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(timestampVal);
        } else {
          dt = DateTime.tryParse(timestampVal.toString()) ?? DateTime.now();
        }
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        loaded[dayKey] ??= [];
        final displayTime = data['time'] ?? _formatTimeFromDateTime(dt);
        loaded[dayKey]!.add({
          'id': id,
          'title': title,
          'time': displayTime,
          'dateTime': dt,
          'note': data['note'] ?? '',
          'doctor': data['doctor'] ?? '',
          'syncCalendar': data['syncCalendar'] ?? true,
          'deviceEventId': data['deviceEventId'],
        });
      }
      setState(() => events = loaded);

      // Handle notifications and device calendar sync
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final syncCalendar = data['syncCalendar'] ?? true;
        final timestampVal = data['timestamp'];
        DateTime dt = (timestampVal is int)
            ? DateTime.fromMillisecondsSinceEpoch(timestampVal)
            : DateTime.tryParse(timestampVal.toString()) ?? DateTime.now();

        if (syncCalendar && dt.isAfter(DateTime.now())) {
          // Schedule notification
          _scheduleNotificationForEvent(
            id: id,
            title: data['title'] ?? 'Reminder',
            scheduledDateTime: dt,
          );

          // Add to device calendar if not already added
          if (data['deviceEventId'] == null) {
            _addToDeviceCalendar(
              title: data['title'] ?? 'Event',
              start: dt,
              description: data['note'],
              location: data['doctor'],
            ).then((deviceEventId) {
              if (deviceEventId != null) {
                // Save device event ID to Firestore
                coll.doc(id).update({'deviceEventId': deviceEventId});
              }
            });
          }
        } else {
          // Cancel notification and remove from device calendar
          _cancelNotificationForEvent(id);
          if (data['deviceEventId'] != null) {
            _removeFromDeviceCalendar(data['deviceEventId']);
            coll.doc(id).update({'deviceEventId': FieldValue.delete()});
          }
        }
      }
    });
  }

  void _startNotesListener() {
    final coll = _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes');
    _notesSub = coll.snapshots().listen((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> loaded = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final content = (data['content'] ?? '').toString();
        final timestampVal = data['timestamp'];
        DateTime dt;
        if (timestampVal is int) {
          dt = DateTime.fromMillisecondsSinceEpoch(timestampVal);
        } else {
          dt = DateTime.tryParse(timestampVal.toString()) ?? DateTime.now();
        }
        final dayKey = DateTime(dt.year, dt.month, dt.day);
        loaded[dayKey] ??= [];
        loaded[dayKey]!.add({'id': id, 'content': content, 'dateTime': dt});
      }
      setState(() => notes = loaded);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  List<Map<String, dynamic>> _getNotesForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return notes[key] ?? [];
  }

  String _formatTimeFromDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showAddNoteDialog({Map<String, dynamic>? editNote}) {
    final TextEditingController _noteController = TextEditingController(
      text: editNote?['content'] ?? '',
    );
    bool showError = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Center(
              child: Text(
                'Add note',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _noteController,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    labelStyle: TextStyle(
                      color: showError ? Colors.red : Colors.grey[600],
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: themeColor2, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: showError
                        ? const Icon(Icons.error, color: Colors.red)
                        : null,
                  ),
                  onChanged: (value) {
                    if (showError && value.isNotEmpty)
                      setState(() => showError = false);
                  },
                ),
                if (showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please enter the text!',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: themeColor2, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (_noteController.text.trim().isEmpty) {
                    setState(() => showError = true);
                    return;
                  }

                  final coll = _firestore
                      .collection('users')
                      .doc(_userId)
                      .collection('notes');
                  final timestamp = _selectedDay ?? DateTime.now();

                  // ── Close dialog FIRST, then save in background ──────────────
                  Navigator.pop(context);

                  if (editNote == null) {
                    await coll.add({
                      'content': _noteController.text.trim(),
                      'timestamp': timestamp.millisecondsSinceEpoch,
                      'createdAt': DateTime.now().millisecondsSinceEpoch,
                    });
                  } else {
                    await coll.doc(editNote['id']).update({
                      'content': _noteController.text.trim(),
                    });
                  }
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: showError ? Colors.grey : themeColor2,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAppointmentDialog({Map<String, dynamic>? editEvent}) {
    showDialog(
      context: context,
      builder: (context) => AppointmentDialog(
        selectedDate:
            editEvent?['dateTime'] ?? (_selectedDay ?? DateTime.now()),
        editEvent: editEvent,
        userId: _userId,
        themeColor: themeColor2,
      ),
    );
  }

  void _deleteEvent(String id) async {
    // Get event data before deleting
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('events')
        .doc(id)
        .get();
    final deviceEventId = doc.data()?['deviceEventId'];

    // Delete from Firestore
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('events')
        .doc(id)
        .delete();

    // Cancel notification
    await _cancelNotificationForEvent(id);

    // Remove from device calendar
    if (deviceEventId != null) {
      await _removeFromDeviceCalendar(deviceEventId);
    }
  }

  void _deleteNote(String id) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .doc(id)
        .delete();
  }

  String _getNepaliDate(DateTime date) {
    picker.NepaliDateTime nepDate = picker.NepaliDateTime.fromDateTime(date);
    return picker.NepaliDateFormat("yyyy MMMM d").format(nepDate);
  }

  String _getEnglishMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F0FB), Color(0xFFEFD9F2), Color(0xFFE0C4EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) => [
                      ..._getEventsForDay(day),
                      ..._getNotesForDay(day),
                    ],
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _calendarFormat = format),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        if (widget.dueDate != null &&
                            isSameDay(date, widget.dueDate)) {
                          return Center(
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 36,
                            ),
                          );
                        }
                        return null;
                      },
                      todayBuilder: (context, date, _) {
                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeColor2,
                              shape: BoxShape.circle,
                            ),
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                      selectedBuilder: (context, date, _) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: themeColor2.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeColor2,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedDay != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedDay!.day} ${_getEnglishMonth(_selectedDay!)} ${_selectedDay!.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getNepaliDate(_selectedDay!),
                      style: const TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_getNotesForDay(_selectedDay!).isNotEmpty) ...[
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._getNotesForDay(_selectedDay!).map((note) {
                        return Slidable(
                          key: ValueKey(note['id']),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.5,
                            children: [
                              SlidableAction(
                                onPressed: (ctx) =>
                                    _showAddNoteDialog(editNote: note),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: (ctx) => _deleteNote(note['id']),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.note,
                                color: Color(0xFFFFB74D),
                              ),
                              title: Text(note['content']),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],

                    if (_getEventsForDay(_selectedDay!).isNotEmpty) ...[
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._getEventsForDay(_selectedDay!).map((event) {
                        final isSynced = event['syncCalendar'] ?? true;
                        return Slidable(
                          key: ValueKey(event['id']),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.5,
                            children: [
                              SlidableAction(
                                onPressed: (ctx) =>
                                    _showAppointmentDialog(editEvent: event),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'Edit',
                              ),
                              SlidableAction(
                                onPressed: (ctx) => _deleteEvent(event['id']),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isSynced ? Icons.event_note : Icons.event_busy,
                                color: isSynced
                                    ? const Color(0xFFE77E7E)
                                    : Colors.grey,
                              ),
                              title: Text(
                                '${event['title']} at ${event['time']}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event['note']?.isNotEmpty == true)
                                    Text(
                                      event['note'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (isSynced)
                                    Text(
                                      '📱 Synced to phone calendar',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else
                                    Text(
                                      '🔕 Notification disabled',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 40,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.note_add, color: themeColor2),
                    title: const Text('Add Note'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddNoteDialog();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.event, color: themeColor2),
                    title: const Text('Add Appointment/Reminder'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAppointmentDialog();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFFEFD9F2),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}

class AppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? editEvent;
  final String userId;
  final Color themeColor;

  const AppointmentDialog({
    Key? key,
    required this.selectedDate,
    this.editEvent,
    required this.userId,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<AppointmentDialog> {
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final _doctorController = TextEditingController();
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  bool syncWithCalendar = true;
  bool showError = false;
  bool showNoteField = false;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    if (widget.editEvent != null) {
      _nameController.text = widget.editEvent!['title'] ?? '';
      _noteController.text = widget.editEvent!['note'] ?? '';
      _doctorController.text = widget.editEvent!['doctor'] ?? 'Doctor';
      selectedDate = widget.editEvent!['dateTime'] ?? widget.selectedDate;
      selectedTime = TimeOfDay(
        hour: selectedDate.hour,
        minute: selectedDate.minute,
      );
      syncWithCalendar = widget.editEvent!['syncCalendar'] ?? true;
      showNoteField = _noteController.text.isNotEmpty;
    } else {
      selectedDate = widget.selectedDate;
      selectedTime = TimeOfDay.now();
      _doctorController.text = 'Doctor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(
                    color: showError ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.themeColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: showError
                      ? const Icon(Icons.error, color: Colors.red)
                      : null,
                ),
                onChanged: (v) {
                  if (showError && v.isNotEmpty)
                    setState(() => showError = false);
                },
              ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Please enter the text!',
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _buildRow(
                Icons.medical_services_outlined,
                widget.themeColor,
                'Doctor',
                _doctorController.text,
                () {},
              ),
              const Divider(height: 1),
              _buildRow(
                Icons.calendar_today_outlined,
                widget.themeColor,
                'Date',
                DateFormat('dd.MM.yyyy').format(selectedDate),
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    locale: const Locale('en', 'US'),
                    builder: (BuildContext context, Widget? child) {
                      return Localizations.override(
                        context: context,
                        locale: const Locale('en', 'US'),
                        child: child,
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
              const Divider(height: 1),
              _buildRow(
                Icons.access_time,
                widget.themeColor,
                'Time',
                _formatTime(selectedTime),
                () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: false),
                        child: Localizations.override(
                          context: context,
                          locale: const Locale('en', 'US'),
                          child: child!,
                        ),
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedTime = picked);
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: widget.themeColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync to Phone Calendar',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Enable notification & calendar sync',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: syncWithCalendar,
                      onChanged: (v) => setState(() => syncWithCalendar = v),
                      activeColor: Colors.white,
                      activeTrackColor: widget.themeColor,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => showNoteField = !showNoteField),
                icon: Icon(
                  showNoteField
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  color: widget.themeColor,
                ),
                label: Text(
                  showNoteField ? 'Remove Note' : 'Add Note',
                  style: TextStyle(color: widget.themeColor),
                ),
              ),
              if (showNoteField) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Note',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: widget.themeColor,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: widget.themeColor, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      if (_nameController.text.trim().isEmpty) {
                        setState(() => showError = true);
                        return;
                      }

                      // ── Close dialog FIRST, then save in background ──────────────
                      Navigator.pop(context);

                      final dt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final coll = _firestore
                          .collection('users')
                          .doc(widget.userId)
                          .collection('events');
                      final timeStr = _formatTime(selectedTime);

                      if (widget.editEvent == null) {
                        await coll.add({
                          'title': _nameController.text.trim(),
                          'time': timeStr,
                          'timestamp': dt.millisecondsSinceEpoch,
                          'createdAt': DateTime.now().millisecondsSinceEpoch,
                          'note': _noteController.text.trim(),
                          'doctor': _doctorController.text.trim(),
                          'syncCalendar': syncWithCalendar,
                        });
                      } else {
                        await coll.doc(widget.editEvent!['id']).update({
                          'title': _nameController.text.trim(),
                          'time': timeStr,
                          'timestamp': dt.millisecondsSinceEpoch,
                          'note': _noteController.text.trim(),
                          'doctor': _doctorController.text.trim(),
                          'syncCalendar': syncWithCalendar,
                        });
                      }
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: showError ? Colors.grey : widget.themeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildRow(
    IconData icon,
    Color color,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
