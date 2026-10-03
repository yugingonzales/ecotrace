import 'package:flutter/material.dart';

import '../../../core/loading/loading_views.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/app_shell.dart';
import '../domain/monitoring_staff.dart';

const double _cardRadius = 24;
const double _fieldRadius = 14;

final OutlineInputBorder _fieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(_fieldRadius),
  borderSide: const BorderSide(color: EcoTraceColors.border),
);

final OutlineInputBorder _focusedFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(_fieldRadius),
  borderSide: const BorderSide(color: EcoTraceColors.leaf, width: 2),
);

final OutlineInputBorder _errorFieldBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(_fieldRadius),
  borderSide: const BorderSide(color: EcoTraceColors.error),
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
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<StaffType> _staffType = ValueNotifier(StaffType.intern);
  final ValueNotifier<bool> _submitting = ValueNotifier(false);
  bool _loginMode = true;

  String? _firstNameValidator(String? value) => _required(value, 'First name');
  String? _lastNameValidator(String? value) => _required(value, 'Last name');
  String? _usernameValidator(String? value) => _required(value, 'Username');

  String? _passwordValidator(String? value) {
    final required = _required(value, 'Password');
    if (required != null) return required;
    return value!.length < 8 ? 'Use at least 8 characters' : null;
  }

  String? _confirmationValidator(String? value) => value != _password.text
      ? 'Passwords do not match'
      : _required(value, 'Confirmation');

  String? _required(String? value, String name) =>
      value == null || value.trim().isEmpty ? '$name is required' : null;

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

  /// Authenticates the officer, then enters the shell.
  ///
  /// `_submitting` stays true across the whole request so the button loader is
  /// visible for the whole wait, not just the navigation frame.
  Future<void> _submit() async {
    if (_submitting.value) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _submitting.value = true;
    await _authenticate();
    if (!mounted) return;
    _submitting.value = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_smoothRoute(const AppShell()));
  }

  /// Stands in for the credentials round-trip. A real implementation awaits the
  /// API call here and surfaces a failure message before `_submit` resets.
  Future<void> _authenticate() =>
      Future<void>.delayed(const Duration(milliseconds: 900));

  static PageRouteBuilder<void> _smoothRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTraceColors.forestDeep,
      body: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: _AuthBackdrop())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _AuthBrand(),
                            const SizedBox(height: 28),
                            _AuthCard(
                              formKey: _formKey,
                              loginMode: _loginMode,
                              firstName: _firstName,
                              middleName: _middleName,
                              lastName: _lastName,
                              username: _username,
                              password: _password,
                              confirmation: _confirmation,
                              obscurePassword: _obscurePassword,
                              staffType: _staffType,
                              submitting: _submitting,
                              firstNameValidator: _firstNameValidator,
                              lastNameValidator: _lastNameValidator,
                              usernameValidator: _usernameValidator,
                              passwordValidator: _passwordValidator,
                              confirmationValidator: _confirmationValidator,
                              onSubmit: _submit,
                              onToggleMode: () =>
                                  setState(() => _loginMode = !_loginMode),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Environmental Tracking System',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.56),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
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
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.loginMode,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.confirmation,
    required this.obscurePassword,
    required this.staffType,
    required this.submitting,
    required this.firstNameValidator,
    required this.lastNameValidator,
    required this.usernameValidator,
    required this.passwordValidator,
    required this.confirmationValidator,
    required this.onSubmit,
    required this.onToggleMode,
  });

  final GlobalKey<FormState> formKey;
  final bool loginMode;
  final TextEditingController firstName;
  final TextEditingController middleName;
  final TextEditingController lastName;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirmation;
  final ValueNotifier<bool> obscurePassword;
  final ValueNotifier<StaffType> staffType;
  final ValueNotifier<bool> submitting;
  final FormFieldValidator<String> firstNameValidator;
  final FormFieldValidator<String> lastNameValidator;
  final FormFieldValidator<String> usernameValidator;
  final FormFieldValidator<String> passwordValidator;
  final FormFieldValidator<String> confirmationValidator;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FormHeading(loginMode: loginMode),
              const SizedBox(height: 22),
              if (!loginMode) ...[
                _SignUpFields(
                  firstName: firstName,
                  middleName: middleName,
                  lastName: lastName,
                  staffType: staffType,
                  firstNameValidator: firstNameValidator,
                  lastNameValidator: lastNameValidator,
                ),
                const SizedBox(height: 16),
              ],
              _AuthField(
                label: 'Username',
                hint: 'Enter your username',
                icon: Icons.person_outline_rounded,
                controller: username,
                autofocus: loginMode,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                validator: usernameValidator,
              ),
              const SizedBox(height: 14),
              ValueListenableBuilder<bool>(
                valueListenable: obscurePassword,
                builder: (context, obscured, _) => _AuthField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  controller: password,
                  obscureText: obscured,
                  textInputAction: loginMode
                      ? TextInputAction.done
                      : TextInputAction.next,
                  validator: passwordValidator,
                  onFieldSubmitted: (_) => onSubmit(),
                  suffix: IconButton(
                    tooltip: obscured ? 'Show password' : 'Hide password',
                    onPressed: () => obscurePassword.value = !obscured,
                    icon: Icon(
                      obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: EcoTraceColors.muted,
                      size: 21,
                    ),
                  ),
                ),
              ),
              if (!loginMode) ...[
                const SizedBox(height: 14),
                ValueListenableBuilder<bool>(
                  valueListenable: obscurePassword,
                  builder: (context, obscured, _) => _AuthField(
                    label: 'Confirm password',
                    hint: 'Re-enter password',
                    icon: Icons.verified_user_outlined,
                    controller: confirmation,
                    obscureText: obscured,
                    textInputAction: TextInputAction.done,
                    validator: confirmationValidator,
                    onFieldSubmitted: (_) => onSubmit(),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              ValueListenableBuilder<bool>(
                valueListenable: submitting,
                builder: (context, isSubmitting, _) => FilledButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: EcoTraceColors.forest,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: EcoTraceColors.forest,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const EcoButtonLoader()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loginMode ? 'Login' : 'Create staff profile',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loginMode
                    ? 'Use your credentials to access field verification.'
                    : 'New profiles are linked to the MONITORING_STAFF audit record.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EcoTraceColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _AuthModeLink(loginMode: loginMode, onTap: onToggleMode),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.staffType,
    required this.firstNameValidator,
    required this.lastNameValidator,
  });

  final TextEditingController firstName;
  final TextEditingController middleName;
  final TextEditingController lastName;
  final ValueNotifier<StaffType> staffType;
  final FormFieldValidator<String> firstNameValidator;
  final FormFieldValidator<String> lastNameValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthField(
          label: 'First name',
          hint: 'Enter your first name',
          icon: Icons.person_outline_rounded,
          controller: firstName,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: firstNameValidator,
        ),
        const SizedBox(height: 14),
        _AuthField(
          label: 'Middle name',
          required: false,
          hint: 'Enter your middle name',
          icon: Icons.person_outline_rounded,
          controller: middleName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthField(
          label: 'Last name',
          hint: 'Enter your last name',
          icon: Icons.person_outline_rounded,
          controller: lastName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: lastNameValidator,
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Staff type'),
        ValueListenableBuilder<StaffType>(
          valueListenable: staffType,
          builder: (context, type, _) => _StaffTypeSelector(
            value: type,
            onChanged: (value) => staffType.value = value,
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.required = true,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.suffix,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool required;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label, required: required),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: EcoTraceColors.muted, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: EcoTraceColors.canvas,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            hintStyle: const TextStyle(
              color: EcoTraceColors.softText,
              fontSize: 14,
            ),
            border: _fieldBorder,
            enabledBorder: _fieldBorder,
            focusedBorder: _focusedFieldBorder,
            errorBorder: _errorFieldBorder,
            focusedErrorBorder: _errorFieldBorder,
            errorStyle: const TextStyle(
              color: EcoTraceColors.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [EcoTraceColors.forest, EcoTraceColors.forestDeep],
        ),
      ),
      child: CustomPaint(painter: _AuthBackdropPainter()),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final highlight = Paint()..color = const Color(0x1FB5EA87);
    final dark = Paint()..color = const Color(0x22000000);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.12),
      size.width * 0.42,
      highlight,
    );
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 0.92),
      size.width * 0.55,
      dark,
    );
    final line = Paint()
      ..color = const Color(0x16FFFFFF)
      ..strokeWidth = 1;
    for (var i = -size.height; i < size.width; i += 44) {
      canvas.drawLine(
        Offset(i.toDouble(), size.height),
        Offset(i + size.height * 0.72, 0),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackdropPainter oldDelegate) => false;
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Image.asset(
              'lib/assets/icons/ecotrace_icon.png',
              fit: BoxFit.cover,
              cacheWidth: 104,
              cacheHeight: 104,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'EcoTrace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      required ? '$label *' : label,
      style: const TextStyle(
        color: EcoTraceColors.forestDark,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}

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
            color: EcoTraceColors.forestDark,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          loginMode
              ? 'Sign in to continue monitoring'
              : 'Join the field verification team',
          style: const TextStyle(
            color: EcoTraceColors.muted,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _AuthModeLink extends StatelessWidget {
  const _AuthModeLink({required this.loginMode, required this.onTap});

  final bool loginMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: loginMode
            ? "Don't have an Account? "
            : 'Already have an Account? ',
        style: const TextStyle(color: EcoTraceColors.muted, fontSize: 13),
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
                  color: EcoTraceColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: EcoTraceColors.forest,
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

class _StaffTypeSelector extends StatelessWidget {
  const _StaffTypeSelector({required this.value, required this.onChanged});

  final StaffType value;
  final ValueChanged<StaffType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StaffType>(
      segments: StaffType.values
          .map(
            (type) =>
                ButtonSegment<StaffType>(value: type, label: Text(type.label)),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        backgroundColor: const WidgetStatePropertyAll(EcoTraceColors.canvas),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? EcoTraceColors.forest
              : EcoTraceColors.muted,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: EcoTraceColors.border),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_fieldRadius),
          ),
        ),
      ),
    );
  }
}
