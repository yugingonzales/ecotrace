import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/staff_auth_screen.dart';

void main() {
  runApp(const EcoTraceApp());
}

class EcoTraceApp extends StatelessWidget {
  const EcoTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrace',
      debugShowCheckedModeBanner: false,
      theme: EcoTraceTheme.light,
      home: const StaffAuthScreen(),
    );
  }
}
