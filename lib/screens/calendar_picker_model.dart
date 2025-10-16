import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

enum CalendarType { nepali, english }

class CalendarPickerModal extends StatefulWidget {
  final CalendarType initialCalendar;
  final picker.NepaliDateTime? initialNepaliDate;
  final DateTime? initialEnglishDate;
  final void Function(
    CalendarType calendar,
    picker.NepaliDateTime nepaliDate,
    DateTime englishDate,
  ) onDateSelected;

  const CalendarPickerModal({
    Key? key,
    required this.initialCalendar,
    this.initialNepaliDate,
    this.initialEnglishDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _CalendarPickerModalState createState() => _CalendarPickerModalState();
}

class _CalendarPickerModalState extends State<CalendarPickerModal> {
  late CalendarType _selectedCalendar;
  picker.NepaliDateTime? _selectedNepaliDate;
  DateTime? _selectedEnglishDate;

  @override
  void initState() {
    super.initState();
    _selectedCalendar = widget.initialCalendar;
    _selectedNepaliDate =
        widget.initialNepaliDate ?? picker.NepaliDateTime.now();
    _selectedEnglishDate = widget.initialEnglishDate ?? DateTime.now();
  }

  void _onDatePicked(picker.NepaliDateTime nepDate, DateTime engDate) {
    widget.onDateSelected(_selectedCalendar, nepDate, engDate);
    Navigator.of(context).pop();
  }

  Future<void> _pickNepaliDate() async {
      final initialDate = _selectedNepaliDate ?? picker.NepaliDateTime.now(); 

    final picked = await picker.showMaterialDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: picker.NepaliDateTime(initialDate.year - 1),
      lastDate: picker.NepaliDateTime.now(),
      
    );
    if (picked != null) {
      setState(() {
        _selectedNepaliDate = picked;
        _selectedEnglishDate = picked.toDateTime();
      });
      _onDatePicked(picked, picked.toDateTime());
    }
  }

  Future<void> _pickEnglishDate() async {
    final initialDate = _selectedEnglishDate ?? DateTime.now(); 

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime.now(),
      locale: const Locale('en', 'US'),
    );
    if (picked != null) {
      setState(() {
        _selectedEnglishDate = picked;
        _selectedNepaliDate = picker.NepaliDateTime.fromDateTime(picked);
      });
      _onDatePicked(_selectedNepaliDate!, picked);
    }
  }

  Widget _buildCalendarToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text('BS', style: TextStyle(fontWeight: FontWeight.bold)),
          selected: _selectedCalendar == CalendarType.nepali,
          selectedColor: Color(0xFFE77E7E),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: _selectedCalendar == CalendarType.nepali
                ? Colors.white
                : Colors.black87,
          ),
          onSelected: (selected) {
            if (selected)
              setState(() => _selectedCalendar = CalendarType.nepali);
          },
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: Text('AD', style: TextStyle(fontWeight: FontWeight.bold)),
          selected: _selectedCalendar == CalendarType.english,
          selectedColor: Color(0xFFE77E7E),
          backgroundColor: Colors.grey.shade200,
          labelStyle: TextStyle(
            color: _selectedCalendar == CalendarType.english
                ? Colors.white
                : Colors.black87,
          ),
          onSelected: (selected) {
            if (selected)
              setState(() => _selectedCalendar = CalendarType.english);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFFBF5C5C),
    );

    final displayedDate = _selectedCalendar == CalendarType.nepali
        ? picker.NepaliDateFormat("yyyy MMMM d").format(_selectedNepaliDate!)
        : DateFormat("yyyy MMMM d", 'en_US').format(_selectedEnglishDate!);

    return Container(
      padding: const EdgeInsets.only(top: 24, left: 32, right: 32, bottom: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 60,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              'Select Date',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE77E7E)),
            ),
            const SizedBox(height: 14),
            _buildCalendarToggle(),
            const SizedBox(height: 28),
            Text(
              displayedDate,
              style: textStyle,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () async {
                if (_selectedCalendar == CalendarType.nepali) {
                  await _pickNepaliDate();
                } else {
                  await _pickEnglishDate();
                }
              },
              icon: Icon(Icons.calendar_today, size: 22),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Pick Date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE77E7E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 5,
                shadowColor: Colors.redAccent.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


