import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/app_shell.dart';
import '../domain/monitoring_staff.dart';

class StaffAuthScreen extends StatefulWidget {
  const StaffAuthScreen({super.key});

  @override
  State<StaffAuthScreen> createState() => _StaffAuthScreenState();
}

class _StaffAuthScreenState extends State<StaffAuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _staffId = TextEditingController();
  final _staffNumber = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loginMode = true;
  bool _obscurePassword = true;
  StaffType _staffType = StaffType.intern;

  // One-shot staggered entrance: header -> card -> form content.
  late final AnimationController _entrance;
  late final Animation<double> _headerAnim;
  late final Animation<double> _cardAnim;
  late final Animation<double> _formAnim;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _headerAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );
    _cardAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic),
    );
    _formAnim = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _staffId.dispose();
    _staffNumber.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _required(String? value, String name) =>
      value == null || value.trim().isEmpty ? '$name is required' : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pushReplacement(_smoothRoute(const AppShell()));
  }

  // Smooth zoom-fade route shared with the splash screen transition.
  static PageRouteBuilder<void> _smoothRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final eased = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: eased,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(eased),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(eased),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: EcoTraceColors.forestDeep),
        child: SafeArea(
          child: Column(
            children: [
              _Entrance(
                animation: _headerAnim,
                slide: 0.03,
                child: const _AuthHeader(),
              ),
              Expanded(
                child: _Entrance(
                  animation: _cardAnim,
                  slide: 0.03,
                  scale: 1.02,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: EcoTraceColors.canvas,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
                      child: Form(
                        key: _formKey,
                        child: _Entrance(
                          animation: _formAnim,
                          slide: 0.03,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AuthTabs(
                                loginMode: _loginMode,
                                onChanged: (value) =>
                                    setState(() => _loginMode = value),
                              ),
                              const SizedBox(height: 28),
                              if (!_loginMode) ...[
                                const _FieldLabel('Staff ID'),
                                TextFormField(
                                  controller: _staffId,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g., STF-00042',
                                  ),
                                  validator: (value) =>
                                      _required(value, 'Staff ID'),
                                ),
                                const SizedBox(height: 18),
                              ],
                              const _FieldLabel('Staff number'),
                              TextFormField(
                                controller: _staffNumber,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'e.g., 239038',
                                ),
                                validator: (value) =>
                                    _required(value, 'Staff number'),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Assigned monitoring personnel number',
                                style: TextStyle(
                                  color: EcoTraceColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                              if (!_loginMode) ...[
                                const SizedBox(height: 18),
                                const _FieldLabel('Staff type'),
                                DropdownButtonFormField<StaffType>(
                                  initialValue: _staffType,
                                  decoration: const InputDecoration(),
                                  items: StaffType.values
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type.label),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () =>
                                        _staffType = value ?? StaffType.intern,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              const _FieldLabel('Password'),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                textInputAction: _loginMode
                                    ? TextInputAction.done
                                    : TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'Enter secure password',
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final required = _required(value, 'Password');
                                  if (required != null) return required;
                                  return value!.length < 8
                                      ? 'Use at least 8 characters'
                                      : null;
                                },
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (!_loginMode) ...[
                                const SizedBox(height: 18),
                                const _FieldLabel('Confirm password'),
                                TextFormField(
                                  controller: _confirmation,
                                  obscureText: _obscurePassword,
                                  decoration: const InputDecoration(
                                    hintText: 'Re-enter secure password',
                                  ),
                                  validator: (value) => value != _password.text
                                      ? 'Passwords do not match'
                                      : _required(value, 'Confirmation'),
                                ),
                              ],
                              const SizedBox(height: 26),
                              FilledButton(
                                onPressed: _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: EcoTraceColors.forest,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(
                                  _loginMode
                                      ? 'Secure login'
                                      : 'Create staff profile',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _loginMode
                                    ? 'Use your assigned staff number and password to access field verification.'
                                    : 'New profiles are linked to the MONITORING_STAFF audit record.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: EcoTraceColors.muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staggers a widget's entrance: fades it in, lifts it from [slide] fraction
/// of its own height, and optionally settles its scale towards 1.0.
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.animation,
    required this.slide,
    this.scale,
    required this.child,
  });

  final Animation<double> animation;
  final double slide;
  final double? scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, slide),
          end: Offset.zero,
        ).animate(animation),
        child: scale == null
            ? child
            : ScaleTransition(
                scale: Tween<double>(begin: scale, end: 1.0).animate(animation),
                child: child,
              ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 36, 30, 58),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoTraceColors.lemon.withValues(alpha: 0.15),
              border: Border.all(
                color: EcoTraceColors.lemon.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: const Text(
              'FIELD\nTEAM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EcoTraceColors.lemon,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EcoTraceColors.lemon,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.layers_outlined,
                    color: EcoTraceColors.forest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'EcoTrace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Environmental Tracking System',
            style: TextStyle(
              color: EcoTraceColors.softText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.loginMode, required this.onChanged});

  final bool loginMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _TabButton(
          label: 'Login',
          active: loginMode,
          onPressed: () => onChanged(true),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _TabButton(
          label: 'Staff sign up',
          active: !loginMode,
          onPressed: () => onChanged(false),
        ),
      ),
    ],
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: active ? EcoTraceColors.forest : const Color(0xFFE8F0EC),
      foregroundColor: active ? Colors.white : EcoTraceColors.muted,
      padding: const EdgeInsets.symmetric(vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$label *',
        style: const TextStyle(
          color: Color(0xFF0A231C),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
