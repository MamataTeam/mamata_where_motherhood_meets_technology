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

  // Color scheme
  final Color primaryPurple = const Color(0xFF667EEA);
  final Color secondaryPurple = const Color(0xFF764BA2);
  final Color accentPink = const Color(0xFFE77E7E);
  final Color lightPink = const Color(0xFFFDEEF0);
  final Color bgLight = const Color(0xFFF5F7FA);
  final Color bgBlue = const Color(0xFFC3CFE2);
  final Color textDark = const Color(0xFF2D3748);
  final Color textGray = const Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.userProfile.fullName);

    if (widget.userProfile.firstDayOfLastPeriod != null) {
      try {
        _selectedDate =
            DateTime.parse(widget.userProfile.firstDayOfLastPeriod!);
      } catch (e) {
        _selectedDate = null;
      }
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
            colorScheme: ColorScheme.light(
              primary: primaryPurple,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
        Get.snackbar(
          'No Changes',
          'You haven\'t made any changes',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: Icon(Icons.info_outline, color: Colors.orange[900]),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Sending update data: $updateData');
      await ApiService.updateUserProfile(updateData);

      Get.snackbar(
        'Success',
        'Profile updated successfully! 💚',
        backgroundColor: const Color(0xFF48BB78),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      Get.back(result: true);
    } catch (e) {
      print('Error in _saveProfile: $e');
      Get.snackbar(
        'Update Failed',
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: const Color(0xFFC53030),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 4),
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: textDark, size: 20),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgLight, bgBlue.withOpacity(0.3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Avatar with Edit Badge
                _buildProfileAvatar(),

                const SizedBox(height: 30),

                // Edit Form Card
                _buildEditCard(),

                const SizedBox(height: 20),

                // Info Note
                _buildInfoNote(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primaryPurple, secondaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.userProfile.photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    widget.userProfile.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, size: 60, color: Colors.white);
                    },
                  ),
                )
              : Icon(Icons.person, size: 60, color: Colors.white),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentPink, const Color(0xFFF56565)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: accentPink.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.edit, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEditCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightPink, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.person_outline, color: accentPink, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Full Name Field
            _buildInputField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Email Field (Read-only)
            _buildInputField(
              label: 'Email Address',
              hint: widget.userProfile.email,
              icon: Icons.email_outlined,
              initialValue: widget.userProfile.email,
              enabled: false,
              helperText: 'Email cannot be changed',
            ),

            const SizedBox(height: 24),

            // Divider
            Divider(color: Colors.grey[200], thickness: 1),
            const SizedBox(height: 24),

            // Medical Section Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightPink, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_outlined,
                      color: accentPink, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // First Day of Last Period
            _buildDateField(),

            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    TextEditingController? controller,
    required String label,
    required String hint,
    required IconData icon,
    String? initialValue,
    String? helperText,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          style: TextStyle(
            color: enabled ? textDark : textGray,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperStyle: TextStyle(
              color: textGray,
              fontSize: 12,
            ),
            hintStyle: TextStyle(color: textGray.withOpacity(0.5)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightPink, Colors.white],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentPink, size: 20),
            ),
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF7FAFC) : const Color(0xFFEDF2F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryPurple, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC53030)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC53030), width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'First Day of Last Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightPink, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today_outlined,
                      color: accentPink, size: 20),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedDate != null
                              ? textDark
                              : textGray.withOpacity(0.5),
                        ),
                      ),
                      if (_selectedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tap to change',
                          style: TextStyle(
                            fontSize: 12,
                            color: textGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.edit_calendar, size: 20, color: textGray),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This will automatically update your due date',
          style: TextStyle(
            color: textGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.save, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentPink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: accentPink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Changes will be reflected immediately after saving',
              style: TextStyle(
                fontSize: 13,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
