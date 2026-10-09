import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_client.dart';
import '../../auth/presentation/staff_auth_screen.dart';
import '../../home/presentation/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Total wall-clock time of the staged splash animation sequence, measured
/// from `initState` to the transition into [StaffAuthScreen].
///
/// The sequence is a chain of sequential delays (150 + 200 + 650 + 300 + 950),
/// so it cannot be expressed as a controller duration. Exposed so tests can
/// outrun it in a single bounded `pump` instead of guessing at a number, and
/// so the launch test fails loudly if the choreography ever changes.
const kSplashSequenceDuration = Duration(milliseconds: 2250);

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneCtrl;
  late final AnimationController _dropCtrl;
  late final AnimationController _scaleCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _subtitleCtrl;

  late final Animation<double> _sceneAnim;
  late final Animation<double> _dropAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Whole scene dissolves in from the native splash background (350ms).
    _sceneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _sceneAnim = CurvedAnimation(parent: _sceneCtrl, curve: Curves.easeInCubic);
    _sceneCtrl.forward();

    // Icon drops in with elastic bounce (700ms)
    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _dropAnim = CurvedAnimation(parent: _dropCtrl, curve: Curves.elasticOut);

    // Icon scales up slightly after landing (500ms)
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);

    // Title and subtitle fade in
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      _dropCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      _scaleCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      _textCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _subtitleCtrl.forward();

      // Hold then transition
      await Future.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;
      assert(
        kSplashSequenceDuration.inMilliseconds == 150 + 200 + 650 + 300 + 950,
        'kSplashSequenceDuration drifted from the staged delays below.',
      );
      final session = await AuthSession.restore();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        _smoothRoute(
          session == null
              ? const StaffAuthScreen()
              : AppShell(user: session.user),
        ),
      );
    } catch (_) {
      // Widget disposed mid-sequence; abort silently.
    }
  }

  @override
  void dispose() {
    _sceneCtrl.dispose();
    _dropCtrl.dispose();
    _scaleCtrl.dispose();
    _textCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: EcoTraceColors.forestDeep),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _sceneAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 10),
                  _buildSubtitle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([_dropCtrl, _scaleCtrl]),
      builder: (context, _) {
        final dropOffset = (1.0 - _dropAnim.value) * 80;
        final scale = 0.7 + _scaleAnim.value * 0.3;
        return Transform.translate(
          offset: Offset(0, dropOffset),
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              'lib/assets/icons/ecotrace_icon.png',
              width: 160,
              height: 160,
              cacheWidth: 320,
              cacheHeight: 320,
              filterQuality: FilterQuality.medium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _textCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
            ),
        child: const Text(
          'EcoTrace',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _subtitleCtrl,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _subtitleCtrl,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: const Text(
          'Environmental Tracking System',
          style: TextStyle(
            color: EcoTraceColors.softText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

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
}
