import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/data/auth_client.dart';
import '../../../../auth/domain/monitoring_staff.dart';
import '../../../../auth/presentation/staff_auth_screen.dart';
import '../../models/user_profile.dart';
import '../../widgets/shared/info_row.dart';
import '../../widgets/shared/section_title.dart';
import '../../widgets/shared/surface_card.dart';
import '../../widgets/shared/top_bar.dart';
import '../sync/sync_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile _profile = currentUserProfile;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: _profile.email);
    _address = TextEditingController(text: _profile.homeAddress);
    _contact = TextEditingController(text: _profile.contactNumber);
  }

  @override
  void dispose() {
    _email.dispose();
    _address.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_email.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _contact.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all contact fields first.')),
      );
      return;
    }
    setState(() {
      _profile = _profile.copyWith(
        email: _email.text.trim(),
        homeAddress: _address.text.trim(),
        contactNumber: _contact.text.trim(),
      );
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile details updated.'),
        backgroundColor: EcoTraceColors.forest,
      ),
    );
  }

  Future<void> _signOut() async {
    await AuthSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const StaffAuthScreen()),
      (_) => false,
    );
  }

  void _cancelEditing() {
    _email.text = _profile.email;
    _address.text = _profile.homeAddress;
    _contact.text = _profile.contactNumber;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: EcoTraceHeader.decoration,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                EcoTraceHeader.topPadding,
                20,
                16,
              ),
              child: Column(
                children: [
                  const TopBar(
                    edgeOffset: 20,
                    showSearch: false,
                    showFilter: false,
                  ),
                  const SizedBox(height: 16),
                  _ProfileIdentity(profile: _profile),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Row(
                children: [
                  const Expanded(child: SectionTitle('Account details')),
                  if (_editing) ...[
                    TextButton(
                      onPressed: _cancelEditing,
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: EcoTraceColors.forest,
                      ),
                      child: const Text('Save'),
                    ),
                  ] else
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              SurfaceCard(
                child: Column(
                  children: [
                    const InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Staff number',
                      value: '239038',
                    ),
                    InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Staff type',
                      value: _profile.staffType.label,
                    ),
                    _ProfileField(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      controller: _email,
                      editing: _editing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _ProfileField(
                      icon: Icons.home_outlined,
                      label: 'Home Address',
                      controller: _address,
                      editing: _editing,
                      maxLines: 2,
                    ),
                    _ProfileField(
                      icon: Icons.phone_outlined,
                      label: 'Contact Number',
                      controller: _contact,
                      editing: _editing,
                      keyboardType: TextInputType.phone,
                    ),
                    InfoRow(
                      icon: Icons.cloud_done_outlined,
                      label: 'Sync status',
                      value: 'All records synced',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SyncDashboardScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EcoTraceColors.error,
                  side: const BorderSide(
                    color: EcoTraceColors.border,
                    width: 2,
                  ),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: EcoTraceColors.lemon,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profile.initials,
                style: const TextStyle(
                  color: EcoTraceColors.forest,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.staffType.label} verifier',
                  style: const TextStyle(
                    color: Color(0xFFA3E635),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.staffId,
                  style: const TextStyle(
                    color: Color(0xFFE8F5ED),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.editing,
    this.keyboardType,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool editing;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (!editing) {
      return InfoRow(icon: icon, label: label, value: controller.text);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: EcoTraceColors.canvas,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: EcoTraceColors.border),
          ),
        ),
      ),
    );
  }
}
