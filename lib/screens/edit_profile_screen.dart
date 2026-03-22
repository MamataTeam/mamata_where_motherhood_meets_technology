import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../APIs/api_service.dart';
import '../user_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  const EditProfileScreen({Key? key, required this.userProfile})
      : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  DateTime? _selectedDate;
  bool _isLoading = false;

  static const Color appPurple = Color(0xFF7B4F9E);
  static const Color bgColor = Color(0xFFF9F0FB);

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.userProfile.fullName);
    if (widget.userProfile.firstDayOfLastPeriod != null) {
      try {
        _selectedDate =
            DateTime.parse(widget.userProfile.firstDayOfLastPeriod!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: appPurple,
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C2C2C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {};

      if (_fullNameController.text.trim() != widget.userProfile.fullName) {
        updateData['full_name'] = _fullNameController.text.trim();
      }

      if (_selectedDate != null) {
        String dateStr = _selectedDate!.toIso8601String().split('T')[0];
        if (dateStr != widget.userProfile.firstDayOfLastPeriod) {
          updateData['first_day_of_last_period'] = dateStr;
        }
      }

      if (updateData.isEmpty) {
        Get.snackbar('No Changes', 'You haven\'t made any changes',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[900],
            margin: const EdgeInsets.all(16),
            borderRadius: 12);
        setState(() => _isLoading = false);
        return;
      }

      await ApiService.updateUserProfile(updateData);

      Get.snackbar('Success', 'Profile updated successfully!',
          backgroundColor: const Color(0xFF48BB78),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2));

      await Future.delayed(const Duration(milliseconds: 500));
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
          'Update Failed', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: const Color(0xFFC53030),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFF2C2C2C)),
                  decoration: _field('Enter your full name'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 24),
                _label('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: widget.userProfile.email,
                  enabled: false,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFFAAAAAA)),
                  decoration: _field('').copyWith(
                    hintText: widget.userProfile.email,
                    helperText: 'Email cannot be changed',
                    helperStyle:
                        const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                  ),
                ),
                const SizedBox(height: 24),
                _label('First Day of Last Period'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedDate != null
                                ? const Color(0xFF2C2C2C)
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: Color(0xFFAAAAAA)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This will automatically update your due date',
                  style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Save Changes',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFAAAAAA),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF888888),
        ),
      );

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: appPurple, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC53030)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC53030), width: 1.5),
        ),
      );
}
