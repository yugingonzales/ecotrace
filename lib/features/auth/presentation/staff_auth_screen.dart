import 'dart:math';
import 'dart:ui';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed canopy atmosphere behind the auth form.
          const _CanopyBackdrop(),
          SafeArea(
            child: Column(
              children: [
                // ── Brand bar ─────────────────────────────────────
                _Entrance(
                  animation: _headerAnim,
                  slide: 0.04,
                  child: const _CompactHeader(),
                ),

                // ── Glass form card ───────────────────────────────
                Expanded(
                  child: _Entrance(
                    animation: _cardAnim,
                    slide: 0.04,
                    scale: 1.015,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 48,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                26,
                                32,
                                26,
                                28,
                              ),
                              child: Form(
                                key: _formKey,
                                child: _Entrance(
                                  animation: _formAnim,
                                  slide: 0.04,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        child: _FormHeading(
                                          key: ValueKey(_loginMode),
                                          loginMode: _loginMode,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      _SegmentedControl(
                                        loginMode: _loginMode,
                                        onChanged: (value) =>
                                            setState(() => _loginMode = value),
                                      ),
                                      const SizedBox(height: 28),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -0.04),
                                                  end: Offset.zero,
                                                ).animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: _loginMode
                                            ? const SizedBox.shrink(
                                                key: ValueKey('login'),
                                              )
                                            : Column(
                                                key: const ValueKey('signup'),
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const SizedBox(height: 22),
                                                  const _FieldLabel('Staff ID'),
                                                  TextFormField(
                                                    controller: _staffId,
                                                    textInputAction:
                                                        TextInputAction.next,
                                                    decoration: _fieldDeco(
                                                      hint: 'e.g. STF-00042',
                                                      icon: Icons
                                                          .fingerprint_rounded,
                                                    ),
                                                    validator: (value) =>
                                                        _required(
                                                          value,
                                                          'Staff ID',
                                                        ),
                                                  ),
                                                  const SizedBox(height: 22),
                                                ],
                                              ),
                                      ),
                                      const _FieldLabel('Staff number'),
                                      TextFormField(
                                        controller: _staffNumber,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        decoration: _fieldDeco(
                                          hint: 'Enter your assigned number',
                                          icon: Icons.badge_outlined,
                                        ),
                                        validator: (value) =>
                                            _required(value, 'Staff number'),
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          'Assigned monitoring personnel number',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -0.04),
                                                  end: Offset.zero,
                                                ).animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: _loginMode
                                            ? const SizedBox.shrink(
                                                key: ValueKey('login'),
                                              )
                                            : Column(
                                                key: const ValueKey('signup'),
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const SizedBox(height: 22),
                                                  const _FieldLabel(
                                                    'Staff type',
                                                  ),
                                                  _StaffTypeSelector(
                                                    value: _staffType,
                                                    onChanged: (t) => setState(
                                                      () => _staffType = t,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 22),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(height: 4),
                                      const _FieldLabel('Password'),
                                      TextFormField(
                                        controller: _password,
                                        obscureText: _obscurePassword,
                                        textInputAction: _loginMode
                                            ? TextInputAction.done
                                            : TextInputAction.next,
                                        decoration: _fieldDeco(
                                          hint: 'Enter your password',
                                          icon: Icons.lock_outline_rounded,
                                          suffix: IconButton(
                                            tooltip: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          final r = _required(
                                            value,
                                            'Password',
                                          );
                                          if (r != null) return r;
                                          return value!.length < 8
                                              ? 'Use at least 8 characters'
                                              : null;
                                        },
                                        onFieldSubmitted: (_) => _submit(),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 260,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, anim) =>
                                            FadeTransition(
                                              opacity: anim,
                                              child: SlideTransition(
                                                position: Tween<Offset>(
                                                  begin: const Offset(0, -0.04),
                                                  end: Offset.zero,
                                                ).animate(anim),
                                                child: child,
                                              ),
                                            ),
                                        child: _loginMode
                                            ? const SizedBox.shrink(
                                                key: ValueKey('login'),
                                              )
                                            : Column(
                                                key: const ValueKey('signup'),
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  const SizedBox(height: 22),
                                                  const _FieldLabel(
                                                    'Confirm password',
                                                  ),
                                                  TextFormField(
                                                    controller: _confirmation,
                                                    obscureText:
                                                        _obscurePassword,
                                                    decoration: _fieldDeco(
                                                      hint: 'Re-enter password',
                                                      icon: Icons
                                                          .verified_user_outlined,
                                                    ),
                                                    validator: (value) =>
                                                        value != _password.text
                                                        ? 'Passwords do not match'
                                                        : _required(
                                                            value,
                                                            'Confirmation',
                                                          ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              EcoTraceColors.forest,
                                              EcoTraceColors.forestDeep,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x4D0B1F17),
                                              blurRadius: 18,
                                              offset: Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: FilledButton(
                                          onPressed: _submit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            minimumSize: const Size.fromHeight(
                                              56,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _loginMode
                                                    ? 'Secure login'
                                                    : 'Create staff profile',
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        _loginMode
                                            ? 'Use your assigned staff number and password to access field verification.'
                                            : 'New profiles are linked to the MONITORING_STAFF audit record.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.50,
                                          ),
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
                        ), // BackdropFilter
                      ), // ClipRRect
                    ), // Padding
                  ), // _Entrance (card)
                ), // Expanded
              ],
            ),
          ),
        ],
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

/// Full-bleed atmospheric backdrop that reproduces the reference image's
/// aerial forest canopy: a deep green base, a sunlit lime glow upper-left,
/// subtle foliage texture, and a soft vignette keeping the form dominant.
class _CanopyBackdrop extends StatelessWidget {
  const _CanopyBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EcoTraceColors.canopy,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sunlit crown glow, displaced upper-centre-left like the reference.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.35, -0.62),
                radius: 1.05,
                colors: [
                  Color(0x8C9CDD6E),
                  Color(0x264C8A47),
                  Colors.transparent,
                ],
                stops: [0.0, 0.42, 0.9],
              ),
            ),
          ),
          // Secondary soft glow low-left, hinting at distant sunlight.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.78, 0.52),
                radius: 0.95,
                colors: [Color(0x2E4C8A47), Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Quiet foliage texture: dark crowns and sparse lime sun-glints.
          const CustomPaint(painter: _CanopyPainter()),
          // Gentle vignette for depth.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.35,
                colors: [Colors.transparent, Color(0x661E0904)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seeded, stable foliage texture drawn behind the auth form. Soft tree-crown
/// mounds and sparse lime glints mimic sunlit canopy without looking noisy.
class _CanopyPainter extends CustomPainter {
  const _CanopyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(1407);

    // Soft dark mounds — individual tree crowns filling the upper field.
    final mound = Paint()..color = const Color(0x12000703);
    for (var i = 0; i < 44; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height * 0.70;
      final radius = 48 + rng.nextDouble() * 104;
      canvas.drawCircle(Offset(cx, cy), radius, mound);
    }

    // Pale-green crowns clustered upper-centre-left (the light cluster).
    final pale = Paint()..color = const Color(0x244C8A47);
    for (var i = 0; i < 16; i++) {
      final cx = size.width * (0.08 + rng.nextDouble() * 0.36);
      final cy = size.height * (0.08 + rng.nextDouble() * 0.34);
      final radius = 44 + rng.nextDouble() * 72;
      canvas.drawCircle(Offset(cx, cy), radius, pale);
    }

    // Soft lime glints scattered like sunlight reflecting on leaves.
    final glint = Paint()..color = const Color(0x33B5EA87);
    for (var i = 0; i < 84; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height * 0.76;
      canvas.drawCircle(Offset(cx, cy), 1.0 + rng.nextDouble() * 2.4, glint);
    }

    // A few firmer lime dots for texture detail.
    final dot = Paint()..color = const Color(0x4DB5EA87);
    for (var i = 0; i < 22; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height * 0.72;
      canvas.drawCircle(Offset(cx, cy), 1.0 + rng.nextDouble() * 1.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _CanopyPainter oldDelegate) => false;
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Image.asset(
              'lib/assets/icons/ecotrace_icon.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'EcoTrace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              shadows: [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.loginMode, required this.onChanged});

  final bool loginMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Sliding white indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: loginMode ? 0 : constraints.maxWidth / 2,
                top: 0,
                width: constraints.maxWidth / 2,
                height: constraints.maxHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: loginMode
                                ? EcoTraceColors.forestDark
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          'Staff sign up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !loginMode
                                ? EcoTraceColors.forestDark
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
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
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.80),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Modern heading that orients the user to the active auth mode.
class _FormHeading extends StatelessWidget {
  const _FormHeading({super.key, required this.loginMode});

  final bool loginMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loginMode ? 'Welcome back' : 'Create your account',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loginMode
              ? 'Sign in to continue monitoring'
              : 'Join the field verification team',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Modern glass-tinted input decoration for the frosted card.
InputDecoration _fieldDeco({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(
      icon,
      color: Colors.white.withValues(alpha: 0.55),
      size: 20,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.10),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: TextStyle(
      color: Colors.white.withValues(alpha: 0.40),
      fontSize: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.15),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.15),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EcoTraceColors.leaf, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EcoTraceColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: EcoTraceColors.error, width: 1.8),
    ),
    errorStyle: const TextStyle(color: EcoTraceColors.error, fontSize: 12),
  );
}

/// Modern segmented selector for staff type with sliding indicator.
class _StaffTypeSelector extends StatelessWidget {
  const _StaffTypeSelector({required this.value, required this.onChanged});

  final StaffType value;
  final ValueChanged<StaffType> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = StaffType.values;
    final idx = items.indexOf(value);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: constraints.maxWidth / items.length * idx,
                top: 0,
                width: constraints.maxWidth / items.length,
                height: constraints.maxHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: items
                    .map(
                      (t) => Expanded(
                        child: GestureDetector(
                          onTap: () => onChanged(t),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: t == value
                                    ? EcoTraceColors.forestDark
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
