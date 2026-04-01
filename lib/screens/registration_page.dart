import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../APIs/api_service.dart';
import 'package:intl/intl.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;
import 'calendar_picker_model.dart';
import 'dashboard.dart';
import 'login_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  CalendarType _selectedCalendar = CalendarType.nepali;
  picker.NepaliDateTime? _pickedNepaliDate;
  DateTime? _pickedGregorianDate;

  bool _obscurePassword = true;
  bool _isLoading = false;

  final Color secondaryPurple = const Color(0xFF764BA2);
  final Color accentPink = const Color(0xFFE77E7E);
  final Color lightPink = const Color(0xFFFDEEF0);
  final Color bgLight = const Color(0xFFF5F7FA);
  final Color bgBlue = const Color(0xFFC3CFE2);
  final Color textDark = const Color(0xFF2D3748);
  final Color textGray = const Color(0xFF718096);
  final Color inputBg = const Color(0xFFF7FAFC);

  void _openCalendarPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CalendarPickerModal(
          initialCalendar: _selectedCalendar,
          initialNepaliDate: _pickedNepaliDate,
          initialEnglishDate: _pickedGregorianDate,
          onDateSelected: (calendar, nepaliDate, englishDate) {
            setState(() {
              _selectedCalendar = calendar;
              _pickedNepaliDate = nepaliDate;
              _pickedGregorianDate = englishDate;
            });
          },
        );
      },
    );
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedGregorianDate == null) {
      Get.snackbar(
        'Error',
        'Please select your last period date',
        backgroundColor: accentPink,
        colorText: Colors.white,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: accentPink,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    final String dateString = DateFormat(
      'yyyy-MM-dd',
    ).format(_pickedGregorianDate!);
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      bool registered = await ApiService.registerUser(
        fullName: _fullNameController.text.trim(),
        email: email,
        password: password,
        first_day_of_last_period: dateString,
      );

      if (!registered) {
        return;
      }

      bool loggedIn = await ApiService.loginUser(
        email: email,
        password: password,
      );

      if (!loggedIn) {
        Get.snackbar(
          'Login Failed',
          'User created but could not log in automatically. Please log in.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.offAll(() => const LoginPage());
        return;
      }

      Get.snackbar(
        'Success',
        'Registration and automatic login successful! 💛',
        backgroundColor: const Color(0xFF48BB78),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );

      Get.offAll(() => const DashboardPage());
    } catch (e) {
      Get.snackbar(
        'Operation Failed',
        e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: const Color(0xFFC53030),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateStr = _selectedCalendar == CalendarType.nepali
        ? (_pickedNepaliDate != null
              ? picker.NepaliDateFormat(
                  "yyyy MMMM d",
                  picker.Language.nepali,
                ).format(_pickedNepaliDate!)
              : '')
        : (_pickedGregorianDate != null
              ? DateFormat("yyyy MMMM d", 'en_US').format(_pickedGregorianDate!)
              : '');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgLight, bgBlue],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),

            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Registration Card
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              hint: 'Your Name',
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Enter your name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Enter email';
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                );
                                if (!emailRegex.hasMatch(v))
                                  return 'Enter a valid email (e.g. name@gmail.com)';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildDateInputField(
                              selectedDateStr: selectedDateStr,
                              onTap: _openCalendarPicker,
                              validator: (_) => _pickedGregorianDate == null
                                  ? 'Please select a date'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              controller: _passwordController,
                              label: 'Create Password',
                              hint: 'At least 6 characters',
                              validator: (v) {
                                if (v == null || v.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Re-enter password',
                              validator: (v) => v == _passwordController.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                            const SizedBox(height: 32),
                            _buildRegisterButton(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildLoginLink(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: secondaryPurple),
      padding: EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Get.offAll(() => const LoginPage()),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              if (Navigator.canPop(context)) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ' Join the Mamata Family',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: Navigator.canPop(context)
                      ? TextAlign.left
                      : TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Let\'s get you started, Mamma 💖',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
          style: TextStyle(color: textDark, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textGray.withOpacity(0.5)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentPink, size: 20),
            ),
            filled: true,
            fillColor: inputBg,
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
              borderSide: BorderSide(color: secondaryPurple, width: 2),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?)? validator,
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
          obscureText: _obscurePassword,
          style: TextStyle(color: textDark, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textGray.withOpacity(0.5)),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: lightPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_outline, color: accentPink, size: 20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textGray,
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: inputBg,
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
              borderSide: BorderSide(color: secondaryPurple, width: 2),
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

  Widget _buildDateInputField({
    required String selectedDateStr,
    required VoidCallback onTap,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last Period Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(text: selectedDateStr),
              style: TextStyle(color: textDark, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Select your last period date',
                hintStyle: TextStyle(color: textGray.withOpacity(0.5)),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: accentPink,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: inputBg,
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
                  borderSide: BorderSide(color: secondaryPurple, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFC53030)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFC53030),
                    width: 2,
                  ),
                ),
              ),
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: secondaryPurple,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: secondaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
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
            : const Text(
                'Register',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: secondaryPurple.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already a member?",
            style: TextStyle(fontSize: 15, color: textGray),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => Get.offAll(() => const LoginPage()),
            child: Text(
              'Log in',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: secondaryPurple,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
