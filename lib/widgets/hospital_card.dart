import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital.dart';
import '../screens/hospital_map_screen.dart';

// Purple/Violet Professional Theme colors
const primaryColor = Color(0xFF667EEA); // Purple
const secondaryColor = Color(0xFF764BA2); // Violet
const lightAccent = Color(0xFFF3F4FF); // Very light purple
const errorColor = Color(0xFFE74C3C); // Muted Red
const textPrimary = Color(0xFF2C3E50); // Dark text
const textSecondary = Color(0xFF7F8C8D); // Gray text
const borderColor = Color(0xFFE5E7F2); // Light purple-gray border
const successColor = Color(0xFF27AE60); // Green

class HospitalCard extends StatelessWidget {
  final Hospital hospital;

  const HospitalCard({super.key, required this.hospital});

  void _launchCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _callHospital(BuildContext context) async {
    final phoneNumbers = hospital.phone
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (phoneNumbers.isEmpty) return;

    if (phoneNumbers.length == 1) {
      _launchCall(phoneNumbers.first);
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => PhoneSelectionDialog(
          hospitalName: hospital.name,
          phoneNumbers: phoneNumbers,
          onPhoneSelected: (phoneNumber) {
            Navigator.of(ctx).pop();
            _launchCall(phoneNumber);
          },
        ),
      );
    }
  }

  List<Widget> _buildPhoneSegments() {
    final phoneNumbers = hospital.phone
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<Widget> segments = [];
    const style = TextStyle(
      fontSize: 14,
      color: primaryColor,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < phoneNumbers.length; i++) {
      segments.add(Text(phoneNumbers[i], style: style));
      if (i < phoneNumbers.length - 1) {
        segments.add(
            Text(', ', style: style.copyWith(decoration: TextDecoration.none)));
      }
    }
    return segments;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(fontSize: 14, color: textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Distance unknown';
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    bool hasGradient = false,
  }) {
    final button = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (hasGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: button,
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital name and distance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hospital.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (hospital.distance != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: lightAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me,
                            size: 14, color: primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          _formatDistance(hospital.distance),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Type chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: primaryColor.withOpacity(0.3), width: 1),
              ),
              child: Text(
                hospital.type,
                style: const TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Address
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              text: hospital.address,
            ),
            const SizedBox(height: 10),

            // Phone - Tappable
            InkWell(
              onTap: () => _callHospital(context),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 16, color: textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 0,
                        runSpacing: 0,
                        children: _buildPhoneSegments(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Specialties
            _buildInfoRow(
              icon: Icons.medical_services_outlined,
              text: hospital.specialties.join(', '),
            ),
            const SizedBox(height: 16),

            // Divider
            const Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hospital.emergency)
                  _buildActionButton(
                    onTap: () => _callHospital(context),
                    icon: Icons.phone_in_talk,
                    label: 'Emergency Call',
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    hasGradient: true,
                  ),
                const SizedBox(width: 10),
                _buildActionButton(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HospitalMapScreen(hospital: hospital),
                    ),
                  ),
                  icon: Icons.map_outlined,
                  label: 'View Map',
                  backgroundColor: lightAccent,
                  foregroundColor: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneSelectionDialog extends StatefulWidget {
  final String hospitalName;
  final List<String> phoneNumbers;
  final Function(String) onPhoneSelected;

  const PhoneSelectionDialog({
    super.key,
    required this.hospitalName,
    required this.phoneNumbers,
    required this.onPhoneSelected,
  });

  @override
  State<PhoneSelectionDialog> createState() => _PhoneSelectionDialogState();
}

class _PhoneSelectionDialogState extends State<PhoneSelectionDialog> {
  String? selectedPhone;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, secondaryColor],
                ),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_in_talk,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.hospitalName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Phone numbers list
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.phoneNumbers.length,
                itemBuilder: (context, index) {
                  final phone = widget.phoneNumbers[index];
                  final isSelected = selectedPhone == phone;

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => selectedPhone = phone),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? primaryColor : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : textSecondary,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 12, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    if (index == 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                successColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color:
                                                  successColor.withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: const Text(
                                            'Primary',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: successColor,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.phone,
                                      size: 14, color: primaryColor),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: borderColor, height: 1),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selectedPhone != null
                            ? () {
                                widget.onPhoneSelected(selectedPhone!);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.call,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'CALL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
