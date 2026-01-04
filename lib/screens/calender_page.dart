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
  final _firestore = FirebaseFirestore.instance;
  final _secureStorage = const FlutterSecureStorage();
  static const String _userIdKey = 'userId';
  late String _userId;

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  final Color themeColor1 = const Color(0xFF667EEA);
  final Color themeColor2 = const Color(0xFF764BA2);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    try {
      tzdata.initializeTimeZones();
    } catch (_) {}

    _initNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveUserIdAndListen();
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      
      await _fln.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
      
      debugPrint('✓ Notifications initialized successfully');
    } catch (e) {
      debugPrint('✗ Error initializing notifications: $e');
    }
  }

  Future<void> _scheduleNotificationForEvent({
    required String id,
    required String title,
    required DateTime scheduledDateTime,
  }) async {
    debugPrint('\n=== SCHEDULING NOTIFICATION ===');
    debugPrint('Event ID: $id');
    debugPrint('Title: $title');
    debugPrint('Scheduled Time: $scheduledDateTime');
    debugPrint('Current Time: ${DateTime.now()}');
    
    if (kIsWeb || scheduledDateTime.isBefore(DateTime.now())) {
      debugPrint('❌ Skipped: Time is in the past or running on web');
      return;
    }

    try {
      final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDateTime, tz.local);
      debugPrint('TZ DateTime: $tzDate');
      
      final androidDetails = AndroidNotificationDetails(
        'event_channel',
        'Event Notifications',
        channelDescription: 'Reminders for your calendar events',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        fullScreenIntent: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
      );
      
      final iosDetails = DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
        sound: 'notification.mp3',
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      final int notifId = id.hashCode & 0x7fffffff;

      debugPrint('Notification ID: $notifId');
      debugPrint('Attempting to schedule...');
      
      await _fln.zonedSchedule(
        notifId,
        'Event Reminder',
        title,
        tzDate,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      
      debugPrint('✓ Notification scheduled successfully!');
      debugPrint('============================\n');
    } catch (e, stackTrace) {
      debugPrint('✗ ERROR scheduling notification: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('============================\n');
    }
  }

  Future<void> _cancelNotificationForEvent(String id) async {
    if (kIsWeb) return;
    try {
      final int notifId = id.hashCode & 0x7fffffff;
      await _fln.cancel(notifId);
      debugPrint('✓ Notification cancelled for ID: $notifId');
    } catch (e) {
      debugPrint('✗ Error cancelling notification: $e');
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
  }

  void _startEventsListener() {
    final coll = _firestore.collection('users').doc(_userId).collection('events');
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
        loaded[dayKey]!.add({'id': id, 'title': title, 'time': displayTime, 'dateTime': dt});
      }
      setState(() => events = loaded);

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final timestampVal = data['timestamp'];
        DateTime dt = (timestampVal is int)
            ? DateTime.fromMillisecondsSinceEpoch(timestampVal)
            : DateTime.tryParse(timestampVal.toString()) ?? DateTime.now();
        if (dt.isAfter(DateTime.now())) {
          _scheduleNotificationForEvent(id: id, title: data['title'] ?? 'Reminder', scheduledDateTime: dt);
        } else {
          _cancelNotificationForEvent(id);
        }
      }
    }, onError: (e) => debugPrint('Error listening events: $e'));
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

  String _formatTimeFromDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  void _addEventDialog({Map<String, dynamic>? editEvent}) {
    final TextEditingController _eventController = TextEditingController(text: editEvent?['title'] ?? '');
    final TextEditingController _timeController = TextEditingController(text: editEvent?['time'] ?? '');
    DateTime selectedDate = editEvent?['dateTime'] ?? (_selectedDay ?? DateTime.now());
    TimeOfDay selectedTime = editEvent != null
        ? TimeOfDay(hour: selectedDate.hour, minute: selectedDate.minute)
        : TimeOfDay.now();
    if (_timeController.text.isEmpty) _timeController.text = _formatTimeOfDay(selectedTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Center(child: Text(editEvent == null ? "Add Event" : "Edit Event", style: const TextStyle(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _eventController,
                decoration: InputDecoration(
                  labelText: "Event Title",
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: themeColor2, width: 2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text("${selectedDate.day}-${selectedDate.month}-${selectedDate.year}")),
                  IconButton(
                    icon: Icon(Icons.edit, color: themeColor1),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        builder: (context, child) {
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(_timeController.text.isEmpty ? "HH:MM AM/PM" : _timeController.text)),
                  IconButton(
                    icon: Icon(Icons.edit, color: themeColor1),
                    onPressed: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Localizations.override(
                            context: context,
                            locale: const Locale('en', 'US'),
                            child: child,
                          );
                        },
                      );

                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                          _timeController.text = _formatTimeOfDay(selectedTime);
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (_eventController.text.isEmpty || _timeController.text.isEmpty) return;
                final scheduledDateTime = DateTime(
                    selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                final coll = _firestore.collection('users').doc(_userId).collection('events');

                if (editEvent == null) {
                  final docRef = await coll.add({
                    'title': _eventController.text.trim(),
                    'time': _timeController.text.trim(),
                    'timestamp': scheduledDateTime.millisecondsSinceEpoch,
                    'createdAt': DateTime.now().millisecondsSinceEpoch,
                  });
                  await _scheduleNotificationForEvent(id: docRef.id, title: _eventController.text.trim(), scheduledDateTime: scheduledDateTime);
                } else {
                  await coll.doc(editEvent['id']).update({
                    'title': _eventController.text.trim(),
                    'time': _timeController.text.trim(),
                    'timestamp': scheduledDateTime.millisecondsSinceEpoch,
                  });
                  await _cancelNotificationForEvent(editEvent['id']);
                  await _scheduleNotificationForEvent(id: editEvent['id'], title: _eventController.text.trim(), scheduledDateTime: scheduledDateTime);
                }

                Navigator.pop(context);
              },
              child: Text(editEvent == null ? "Add" : "Update"),
            ),
          ],
        );
      }),
    );
  }

  void _deleteEvent(String id) async {
    final coll = _firestore.collection('users').doc(_userId).collection('events');
    await coll.doc(id).delete();
    await _cancelNotificationForEvent(id);
  }

  String _getNepaliDate(DateTime date) {
    picker.NepaliDateTime nepDate = picker.NepaliDateTime.fromDateTime(date);
    return picker.NepaliDateFormat("yyyy MMMM d").format(nepDate);
  }

  String _getEnglishMonth(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final nepaliStyle = const TextStyle(fontFamily: 'NotoSansDevanagari', fontStyle: FontStyle.italic, fontSize: 16, color: Color(0xFF718096));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [themeColor1, themeColor2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) => setState(() => _calendarFormat = format),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        if (widget.dueDate != null && isSameDay(date, widget.dueDate)) {
                          return Center(child: Icon(Icons.favorite, color: Colors.red, size: 36));
                        }
                        return Center(child: Text('${date.day}', style: const TextStyle(color: Colors.black87)));
                      },
                      todayBuilder: (context, date, _) {
                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.favorite, color: themeColor2, size: 36),
                              Text('${date.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                      selectedBuilder: (context, date, _) {
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(color: themeColor2.withOpacity(0.3), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text('${date.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      },
                      markerBuilder: (context, date, eventsForDay) {
                        if (eventsForDay.isNotEmpty) {
                          return Positioned(bottom: 4, child: Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor1)));
                        }
                        return const SizedBox();
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
                    Text('${_selectedDay!.day} ${_getEnglishMonth(_selectedDay!)} ${_selectedDay!.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                    Text(_getNepaliDate(_selectedDay!), style: nepaliStyle),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _addEventDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._getEventsForDay(_selectedDay!).asMap().entries.map((entry) {
                      final idx = entry.key;
                      final event = entry.value;
                      return Slidable(
                        key: ValueKey('${event['id']}_$idx'),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.5,
                          children: [
                            SlidableAction(
                              onPressed: (ctx) => _addEventDialog(editEvent: event),
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
                        child: ListTile(
                          leading: const Icon(Icons.event_note, color: Color(0xFFE77E7E)),
                          title: Text('${event['title']} at ${event['time']}'),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}