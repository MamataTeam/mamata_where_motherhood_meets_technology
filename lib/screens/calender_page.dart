import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;


class MyCalendarPage extends StatefulWidget {
  final DateTime? dueDate;
  const MyCalendarPage({Key? key, this.dueDate}) : super(key: key);

  @override
  _MyCalendarPageState createState() => _MyCalendarPageState();
}

class _MyCalendarPageState extends State<MyCalendarPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<String>> events = {};

  final Color themeColor1 = const Color(0xFF667EEA);
  final Color themeColor2 = const Color(0xFF764BA2);

   @override
  void initState() {
    super.initState();
    //Show today by default 
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

    // Return events for a given day
  List<String> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? [];
  }

 void _addEventDialog() {
  final TextEditingController _eventController = TextEditingController();

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
        child: Text(
          "Add Event",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
        content: TextField(
  controller: _eventController,
  cursorColor: themeColor2, 
  decoration: InputDecoration(
    labelText: "Event Title",
    floatingLabelStyle: const TextStyle(color: Colors.black54),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: themeColor2, width: 2),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: themeColor1, width: 1.5),
    ),
  ),
),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_eventController.text.isEmpty) return;

              final eventDate = DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

              setState(() {
                if (!events.containsKey(eventDate)) {
                  events[eventDate] = [];
                }
                events[eventDate]!.add(_eventController.text);
              });

              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeColor1, themeColor2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFC3CFE2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16), // optional padding
        child: SingleChildScrollView(
          child: Column(
           children: [
            // Calendar Card
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
                  lastDay: DateTime.utc(2030, 12, 31),
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
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        if (widget.dueDate != null && isSameDay(date, widget.dueDate)) {
                          return Center(
                            child: Icon(
                              Icons.favorite, 
                              color: Colors.red,
                              size: 36),
                          );
                        }
                        return Center(child: Text('${date.day}', style: const TextStyle(color: Colors.black87)));
                      },
                      todayBuilder: (context, date, _) {
                        return Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.favorite, color: themeColor2, size: 36),
                              Text('${date.day}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                      selectedBuilder: (context, date, _) {
                        if (widget.dueDate != null && isSameDay(date, widget.dueDate)) {
                          return Center(child: Icon(
                            Icons.favorite,
                            color: Colors.red.withOpacity(0.3),
                            size: 36));
                        }
                        return Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: themeColor2.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text('${date.day}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      },
                      markerBuilder: (context, date, eventsForDay) {
                        if (eventsForDay.isNotEmpty) {
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: themeColor1),
                            ),
                          );
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
                    Text(
                      '${_selectedDay!.day} ${_getEnglishMonth(_selectedDay!)} ${_selectedDay!.year}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_getNepaliDate(_selectedDay!)}',
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xFF718096), fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [themeColor1, themeColor2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _addEventDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Event', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_getEventsForDay(_selectedDay!).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Events:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                          ..._getEventsForDay(_selectedDay!).map(
                            (event) => ListTile(
                              leading: const Icon(Icons.event_note, color: Color(0xFFE77E7E)),
                              title: Text(event,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748))),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEnglishMonth(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[date.month - 1];
  }

   String _getNepaliDate(DateTime date) {
  // Convert English DateTime to NepaliDateTime
  picker.NepaliDateTime nepDate = picker.NepaliDateTime.fromDateTime(date);

  // Format
  return picker.NepaliDateFormat("yyyy MMMM d").format(nepDate);
}
}
