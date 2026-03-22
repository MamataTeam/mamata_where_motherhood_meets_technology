import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hospital.dart';
import '../screens/hospital_map_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _purple = Color(0xFF764BA2);
const _purpleSoft = Color(0xFFF3EDF9);
const _gold = Color(0xFFC9933A);
const _goldSoft = Color(0xFFFBF3E6);
const _crimson = Color(0xFFB83232);
const _crimsonSoft = Color(0xFFFAECEC);
const _green = Color(0xFF27AE60);
const _greenSoft = Color(0xFFE8F8EE);
const _cardBg = Color(0xFFFFFFFF);
const _ink = Color(0xFF1A1A2E);
const _sub = Color(0xFF6B6B8A);
const _ghost = Color(0xFFBBBBCC);
const _divider = Color(0xFFF0ECF8);

class HospitalCard extends StatefulWidget {
  final Hospital hospital;
  const HospitalCard({super.key, required this.hospital});
  @override
  State<HospitalCard> createState() => _HospitalCardState();
}

class _HospitalCardState extends State<HospitalCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggleExpand() => setState(() => _expanded = !_expanded);

  void _launchCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _callHospital(BuildContext context) async {
    final numbers = widget.hospital.phone
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (numbers.isEmpty) return;
    if (numbers.length == 1) {
      _launchCall(numbers.first);
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => _PhoneDialog(
          hospitalName: widget.hospital.name,
          phoneNumbers: numbers,
          onPhoneSelected: (p) {
            Navigator.of(ctx).pop();
            _launchCall(p);
          },
        ),
      );
    }
  }

  String _fmt(double? m) {
    if (m == null) return '';
    return m < 1000
        ? '${m.toStringAsFixed(0)} m'
        : '${(m / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hospital;
    const showCount = 3;
    final allSpecs = h.specialties;
    final hasMore = allSpecs.length > showCount;
    final visibleSpecs = _expanded
        ? allSpecs
        : allSpecs.take(showCount).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: _purple.withOpacity(0.04),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HospitalMapScreen(hospital: h)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: avatar + name + distance ─────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Initial avatar
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _purpleSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          h.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + address
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.name,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 11,
                                color: _ghost,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  h.address,
                                  style: const TextStyle(
                                    color: _ghost,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Distance badge
                    if (h.distance != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2DFF0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fmt(h.distance),
                              style: const TextStyle(
                                color: _purple,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'away',
                              style: TextStyle(
                                color: _ghost,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
                Container(height: 1, color: _divider),
                const SizedBox(height: 10),

                // ── Type + emergency ──────────────────────────────────
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    _TypeBadge(label: h.type),
                    if (h.emergency) const _EmergencyBadge(),
                  ],
                ),

                // ── Specialties with expand/collapse ─────────────────
                if (allSpecs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...visibleSpecs.map((s) => _SpecTag(label: s)),
                      if (hasMore && !_expanded)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleExpand,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _purple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${allSpecs.length - showCount} more',
                                  style: const TextStyle(
                                    color: _purple,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 14,
                                  color: _purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (hasMore && _expanded)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleExpand,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _purple.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Show less',
                                  style: TextStyle(
                                    color: _purple,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 14,
                                  color: _purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Container(height: 1, color: _divider),
                const SizedBox(height: 10),

                // ── Phone ─────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: _ghost),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        h.phone.split(',').first.trim(),
                        style: const TextStyle(
                          color: _sub,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────
                Row(
                  children: [
                    if (h.emergency) ...[
                      Expanded(
                        child: _CardBtn(
                          label: 'Call Now',
                          icon: Icons.phone_rounded,
                          bg: _crimson,
                          onTap: () => _callHospital(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: _CardBtn(
                        label: 'Directions',
                        icon: Icons.near_me_rounded,
                        bg: _purple,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalMapScreen(hospital: h),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  const _TypeBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _purpleSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _purple.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _purple,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmergencyBadge extends StatelessWidget {
  const _EmergencyBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _greenSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _green.withOpacity(0.25), width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emergency_rounded, size: 10, color: _green),
          SizedBox(width: 4),
          Text(
            '24h Emergency',
            style: TextStyle(
              color: _green,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecTag extends StatelessWidget {
  final String label;
  const _SpecTag({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _divider, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _sub,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  const _CardBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phone dialog ──────────────────────────────────────────────────────────────

class _PhoneDialog extends StatefulWidget {
  final String hospitalName;
  final List<String> phoneNumbers;
  final Function(String) onPhoneSelected;
  const _PhoneDialog({
    required this.hospitalName,
    required this.phoneNumbers,
    required this.onPhoneSelected,
  });
  @override
  State<_PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<_PhoneDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: _cardBg,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _purpleSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    color: _purple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Number',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.hospitalName,
                        style: const TextStyle(color: _ghost, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone options
            ...widget.phoneNumbers.asMap().entries.map((entry) {
              final i = entry.key;
              final phone = entry.value;
              final sel = _selected == phone;
              return GestureDetector(
                onTap: () => setState(() => _selected = phone),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? _purpleSoft : const Color(0xFFF7F5FC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? _purple : _divider,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sel
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 18,
                        color: sel ? _purple : _ghost,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phone,
                          style: TextStyle(
                            color: sel ? _purple : _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (i == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _goldSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Cancel / Call buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _divider),
                      ),
                      child: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: _sub,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selected != null
                        ? () => widget.onPhoneSelected(_selected!)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selected != null
                            ? _crimson
                            : _ghost.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.call_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}