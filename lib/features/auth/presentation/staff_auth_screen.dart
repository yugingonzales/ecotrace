import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/presentation/app_shell.dart';
import '../domain/monitoring_staff.dart';

// ── Shared look-and-feel constants ────────────────────────────────────────────
// Hoisted to file scope so every form field reuses the same border / hint /
// radius instances — stable identities mean zero per-build allocation here,
// and OutlineInputBorders are not const-constructible with rounded corners.

/// Corner radius of the glass form card and its frosted container.
const double _glassRadius = 28;

/// Corner radius shared by input fields and the submit button.
const double _fieldRadius = 16;

/// Idle (enabled / unfocused) field border used by every input in the card.
final OutlineInputBorder _idleFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(_fieldRadius),
  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
);

/// Focused field border — leaf accent, same width as idle to prevent layout shift.
const OutlineInputBorder _focusedFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(_fieldRadius)),
  borderSide: BorderSide(color: EcoTraceColors.leaf, width: 1),
);

/// Field border shown while a validation error is pending.
const OutlineInputBorder _errorFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(_fieldRadius)),
  borderSide: BorderSide(color: EcoTraceColors.error, width: 1),
);

/// Field border for a focused field with an active validation error.
const OutlineInputBorder _focusedErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(_fieldRadius)),
  borderSide: BorderSide(color: EcoTraceColors.error, width: 1),
);

/// Hint text style shared by every input field.
final TextStyle _fieldHintStyle = TextStyle(
  color: Colors.white.withValues(alpha: 0.40),
  fontSize: 14,
);

class StaffAuthScreen extends StatefulWidget {
  const StaffAuthScreen({super.key});

  @override
  State<StaffAuthScreen> createState() => _StaffAuthScreenState();
}

class _StaffAuthScreenState extends State<StaffAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _loginMode = true;
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<StaffType> _staffType = ValueNotifier(StaffType.intern);
  final ValueNotifier<bool> _submitting = ValueNotifier(false);

  // Validators stay stable per State instance: private methods hoisted out of
  // build so each TextFormField keeps a fixed callback across rebuilds instead
  // of allocating a brand-new closure on every keystroke / focus / validation.
  String? _firstNameValidator(String? v) => _required(v, 'First name');
  String? _lastNameValidator(String? v) => _required(v, 'Last name');
  String? _usernameValidator(String? v) => _required(v, 'Username');
  String? _passwordValidator(String? value) {
    final r = _required(value, 'Password');
    if (r != null) return r;
    return value!.length < 8 ? 'Use at least 8 characters' : null;
  }

  String? _confirmationValidator(String? value) => value != _password.text
      ? 'Passwords do not match'
      : _required(value, 'Confirmation');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    _obscurePassword.dispose();
    _staffType.dispose();
    _submitting.dispose();
    super.dispose();
  }

  String? _required(String? value, String name) =>
      value == null || value.trim().isEmpty ? '$name is required' : null;

  // Async-ready auth seam: yields one microtask today, but is shaped so real
  // credential verification (API / local audit store) can slot in later
  // without touching the UI. The submit button shows a spinner only while
  // pending, so the current "instant success" path renders identically.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitting.value = true;
    await Future<void>.value();
    if (!mounted) return;
    _submitting.value = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_smoothRoute(const AppShell()));
  }

  // Snappy fade route shared with the splash screen transition. Scale and
  // slide were removed: animating a transform re-rasterizes the heavy
  // glass-blur surface at a new size every frame, which is what made entry
  // feel laggy. Opacity is composited at the already-rasterized size, so a
  // short fade is effectively free.
  static PageRouteBuilder<void> _smoothRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed canopy atmosphere behind the auth form. Trapped in its
          // own layer so the 24-sigma glass blur, focus changes, and keyboard
          // events never re-rasterize its ~166 circle strokes.
          const RepaintBoundary(child: _CanopyBackdrop()),
          SafeArea(
            child: Column(
              children: [
                // ── Institution logos (top-left) ────────────────
                const RepaintBoundary(child: _InstitutionLogos()),

                // EcoTrace wordmark -- floats in the gap roughly halfway
                // between the header logos and the form card. It stays
                // OUTSIDE the scroll view below, so scrolling the form or
                // opening the keyboard never moves or hides it. The flex
                // void above collapses gracefully on short screens,
                // sliding the brand back up beside the header.
                const Spacer(),
                const _EcoTraceBrand(),
                const SizedBox(height: 20),

                // -- Glass form card -------------------------------
                // Only this region lifts above the keyboard; the
                // backdrop and branding stay pinned to the full screen.
                Expanded(
                  // Large flex keeps the card centered in most of the
                  // remaining height while the brand floats above it.
                  flex: 8,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RepaintBoundary(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          _glassRadius,
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 24,
                                            sigmaY: 24,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    _glassRadius,
                                                  ),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.35,
                                                ),
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
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    26,
                                                    18,
                                                    26,
                                                    20,
                                                  ),
                                              child: Form(
                                                key: _formKey,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    _FormHeading(
                                                      loginMode: _loginMode,
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _loginMode
                                                        ? const SizedBox.shrink()
                                                        : Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              const _FieldLabel(
                                                                'First name',
                                                              ),
                                                              TextFormField(
                                                                controller:
                                                                    _firstName,
                                                                autofocus: true,
                                                                textCapitalization:
                                                                    TextCapitalization
                                                                        .words,
                                                                textInputAction:
                                                                    TextInputAction
                                                                        .next,
                                                                decoration:
                                                                    _fieldDeco(
                                                                      hint: 'Enter your first name',
                                                                      icon: Icons
                                                                          .person_outline_rounded,
                                                                    ),
                                                                validator:
                                                                    _firstNameValidator,
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              const _FieldLabel(
                                                                'Middle name',
                                                                required: false,
                                                              ),
                                                              TextFormField(
                                                                controller:
                                                                    _middleName,
                                                                textCapitalization:
                                                                    TextCapitalization
                                                                        .words,
                                                                textInputAction:
                                                                    TextInputAction
                                                                        .next,
                                                                decoration:
                                                                    _fieldDeco(
                                                                      hint: 'Enter your middle name',
                                                                      icon: Icons
                                                                          .person_outline_rounded,
                                                                    ),
                                                                // Optional: no
                                                                // validator.
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              const _FieldLabel(
                                                                'Last name',
                                                              ),
                                                              TextFormField(
                                                                controller:
                                                                    _lastName,
                                                                textCapitalization:
                                                                    TextCapitalization
                                                                        .words,
                                                                textInputAction:
                                                                    TextInputAction
                                                                        .next,
                                                                decoration:
                                                                    _fieldDeco(
                                                                      hint: 'Enter your last name',
                                                                      icon: Icons
                                                                          .person_outline_rounded,
                                                                    ),
                                                                validator:
                                                                    _lastNameValidator,
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                            ],
                                                          ),
                                                    _loginMode
                                                        ? const SizedBox.shrink()
                                                        : Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              const _FieldLabel(
                                                                'Staff type',
                                                              ),
                                                              ValueListenableBuilder<
                                                                StaffType
                                                              >(
                                                                valueListenable:
                                                                    _staffType,
                                                                builder:
                                                                    (
                                                                      context,
                                                                      type,
                                                                      _,
                                                                    ) => _StaffTypeSelector(
                                                                      value:
                                                                          type,
                                                                      onChanged:
                                                                          (
                                                                            t,
                                                                          ) => _staffType.value =
                                                                              t,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                            ],
                                                          ),
                                                    const SizedBox(height: 4),
                                                    const _FieldLabel(
                                                      'Username',
                                                    ),
                                                    TextFormField(
                                                      controller: _username,
                                                      autofocus: true,
                                                      autocorrect: false,
                                                      enableSuggestions: false,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      decoration: _fieldDeco(
                                                        hint: 'Enter your username',
                                                        icon: Icons
                                                            .person_rounded,
                                                      ),
                                                      validator:
                                                          _usernameValidator,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const _FieldLabel(
                                                      'Password',
                                                    ),
                                                    ValueListenableBuilder<
                                                      bool
                                                    >(
                                                      valueListenable:
                                                          _obscurePassword,
                                                      builder: (context, obscured, _) {
                                                        return TextFormField(
                                                          controller: _password,
                                                          obscureText: obscured,
                                                          textInputAction:
                                                              _loginMode
                                                              ? TextInputAction
                                                                    .done
                                                              : TextInputAction
                                                                    .next,
                                                          decoration: _fieldDeco(
                                                            hint: 'Enter your password',
                                                            icon: Icons
                                                                .lock_outline_rounded,
                                                            suffix: IconButton(
                                                              tooltip: obscured
                                                                  ? 'Show password'
                                                                  : 'Hide password',
                                                              onPressed: () =>
                                                                  _obscurePassword
                                                                          .value =
                                                                      !obscured,
                                                              icon: Icon(
                                                                obscured
                                                                    ? Icons
                                                                          .visibility_outlined
                                                                    : Icons
                                                                          .visibility_off_outlined,
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.7,
                                                                    ),
                                                                size: 22,
                                                              ),
                                                            ),
                                                          ),
                                                          validator:
                                                              _passwordValidator,
                                                          onFieldSubmitted: (
                                                            _,
                                                          ) => _submit(),
                                                        );
                                                      },
                                                    ),
                                                    _loginMode
                                                        ? const SizedBox.shrink()
                                                        : Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              const _FieldLabel(
                                                                'Confirm password',
                                                              ),
                                                              ValueListenableBuilder<
                                                                bool
                                                              >(
                                                                valueListenable:
                                                                    _obscurePassword,
                                                                builder: (context, obscured, _) => TextFormField(
                                                                  controller:
                                                                      _confirmation,
                                                                  obscureText:
                                                                      obscured,
                                                                  decoration:
                                                                      _fieldDeco(
                                                                        hint: 'Re-enter password',
                                                                        icon: Icons
                                                                            .verified_user_outlined,
                                                                      ),
                                                                  validator:
                                                                      _confirmationValidator,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    const SizedBox(height: 18),
                                                    ValueListenableBuilder<
                                                      bool
                                                    >(
                                                      valueListenable:
                                                          _submitting,
                                                      builder: (context, submitting, _) {
                                                        return Container(
                                                          decoration: BoxDecoration(
                                                            gradient: const LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                EcoTraceColors
                                                                    .forest,
                                                                EcoTraceColors
                                                                    .forestDeep,
                                                              ],
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  _fieldRadius,
                                                                ),
                                                            boxShadow: const [
                                                              BoxShadow(
                                                                color: Color(
                                                                  0x4D0B1F17,
                                                                ),
                                                                blurRadius: 18,
                                                                offset: Offset(
                                                                  0,
                                                                  8,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: FilledButton(
                                                            onPressed:
                                                                submitting
                                                                ? null
                                                                : _submit,
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              foregroundColor:
                                                                  Colors.white,
                                                              elevation: 0,
                                                              shadowColor: Colors
                                                                  .transparent,
                                                              minimumSize:
                                                                  const Size.fromHeight(
                                                                    56,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      _fieldRadius,
                                                                    ),
                                                              ),
                                                              textStyle:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    letterSpacing:
                                                                        0.4,
                                                                  ),
                                                            ),
                                                            child: submitting
                                                                ? const SizedBox(
                                                                    width: 20,
                                                                    height: 20,
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2.4,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  )
                                                                : Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      Text(
                                                                        _loginMode
                                                                            ? 'Login'
                                                                            : 'Create staff profile',
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            8,
                                                                      ),
                                                                      const Icon(
                                                                        Icons
                                                                            .arrow_forward_rounded,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                    ],
                                                                  ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      _loginMode
                                                          ? 'Use your credentials to access field verification.'
                                                          : 'New profiles are linked to the MONITORING_STAFF audit record.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.50,
                                                            ),
                                                        fontSize: 12,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 18),
                                                    _AuthModeLink(
                                                      loginMode: _loginMode,
                                                      onTap: () => setState(
                                                        () => _loginMode =
                                                            !_loginMode,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ), // BackdropFilter
                                      ), // ClipRRect
                                    ), // RepaintBoundary
                                  ], // Column children
                                ), // Column
                              ), // Padding
                            ), // Center
                          ), // ConstrainedBox
                        ); // SingleChildScrollView (return)
                      },
                    ), // LayoutBuilder
                  ), // AnimatedPadding
                ), // Expanded
              ], // Column children
            ), // Column
          ), // SafeArea
        ], // Stack children
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

/// Left-aligned institution logos shown in the top-left corner: a pair of
/// rounded-square badges with the university and college branding.
class _InstitutionLogos extends StatelessWidget {
  const _InstitutionLogos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: const [
          _LogoBadge(assetPath: 'lib/assets/icons/university_logo.jpg'),
          SizedBox(width: 10),
          _LogoBadge(assetPath: 'lib/assets/icons/college_logo.jpg'),
        ],
      ),
    );
  }
}

/// Centered EcoTrace wordmark shown just above the glass form card.
class _EcoTraceBrand extends StatelessWidget {
  const _EcoTraceBrand();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LogoBadge(
            assetPath: 'lib/assets/icons/ecotrace_icon.png',
            size: 64,
          ),
          const SizedBox(width: 14),
          const Text(
            'EcoTrace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
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

/// Rounded-square logo tile reusing the EcoTrace icon container styling:
/// frosted fill, soft white border, and a subtle drop shadow for depth.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.assetPath, this.size = 52});

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.required = true});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        required ? '$label *' : label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.80),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// Navigation-style prompt below the submit button that links between the
/// login and sign-up views of the staff auth flow. The action phrase renders
/// as an underlined accent link.
class _AuthModeLink extends StatelessWidget {
  const _AuthModeLink({required this.loginMode, required this.onTap});

  final bool loginMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.60);
    return Text.rich(
      TextSpan(
        text: loginMode
            ? "Don't have an Account? "
            : 'Already have an Account? ',
        style: TextStyle(color: muted, fontSize: 13),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                loginMode ? 'Sign Up.' : 'Sign In.',
                style: const TextStyle(
                  color: EcoTraceColors.leaf,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: EcoTraceColors.leaf,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Modern heading that orients the user to the active auth mode.
class _FormHeading extends StatelessWidget {
  const _FormHeading({required this.loginMode});

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
    hintStyle: _fieldHintStyle,
    border: _idleFieldBorder,
    enabledBorder: _idleFieldBorder,
    focusedBorder: _focusedFieldBorder,
    errorBorder: _errorFieldBorder,
    focusedErrorBorder: _focusedErrorBorder,
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
              Positioned(
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
